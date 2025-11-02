import serial
import serial.tools.list_ports
import time

def listar_puertos():
    """Lista todos los puertos COM disponibles"""
    print("\n=== Puertos COM disponibles ===")
    puertos = serial.tools.list_ports.comports()
    if not puertos:
        print("No se encontraron puertos COM")
        return None
    
    for i, puerto in enumerate(puertos):
        print(f"{i+1}. {puerto.device} - {puerto.description}")
    
    return puertos

def seleccionar_puerto(puertos):
    """Permite al usuario seleccionar un puerto"""
    while True:
        try:
            seleccion = int(input("\nSelecciona el número de puerto (o 0 para salir): "))
            if seleccion == 0:
                return None
            if 1 <= seleccion <= len(puertos):
                return puertos[seleccion - 1].device
            print("Selección inválida")
        except ValueError:
            print("Por favor ingresa un número válido")

def modo_alu(ser):
    """Modo operaciones ALU"""
    print("\n" + "="*60)
    print("              MODO OPERACIONES ALU")
    print("="*60)
    print("\nOperaciones disponibles:")
    print("  0x20 (32)  - ADD  : A + B")
    print("  0x22 (34)  - SUB  : A - B")
    print("  0x24 (36)  - AND  : A & B")
    print("  0x25 (37)  - OR   : A | B")
    print("  0x26 (38)  - XOR  : A ^ B")
    print("  0x27 (39)  - NOR  : ~(A | B)")
    print("  0x02 (2)   - SRL  : A >> B (lógico)")
    print("  0x03 (3)   - SRA  : A >>> B (aritmético)")
    print("\nFormato: Se envían 3 bytes: [A] [B] [OP]")
    print("Escribe 'salir' para volver al menú.\n")
    
    operaciones = {
        '1': (0x20, 'ADD', '+'),
        '2': (0x22, 'SUB', '-'),
        '3': (0x24, 'AND', '&'),
        '4': (0x25, 'OR', '|'),
        '5': (0x26, 'XOR', '^'),
        '6': (0x27, 'NOR', 'NOR'),
        '7': (0x02, 'SRL', '>>'),
        '8': (0x03, 'SRA', '>>>'),
    }
    
    while True:
        print("\n" + "-"*60)
        print("Selecciona operación:")
        for key, (code, name, symbol) in operaciones.items():
            print(f"  {key}. {name:4s} (0x{code:02X}) - A {symbol} B")
        print("  9. Enviar bytes personalizados")
        print("  0. Salir")
        
        opcion = input("\nOpción: ").strip()
        
        if opcion == '0' or opcion.lower() == 'salir':
            break
        
        if opcion == '9':
            # Modo personalizado
            try:
                a = int(input("Valor A (0-255): "))
                b = int(input("Valor B (0-255): "))
                op = int(input("Código operación (hex, ej: 0x20): "), 0)
                
                if not (0 <= a <= 255 and 0 <= b <= 255 and 0 <= op <= 255):
                    print("Error: valores fuera de rango")
                    continue
                    
            except ValueError:
                print("Error: formato inválido")
                continue
        
        elif opcion in operaciones:
            op_code, op_name, op_symbol = operaciones[opcion]
            
            try:
                a = int(input(f"Valor A (0-255): "))
                b = int(input(f"Valor B (0-255): "))
                
                if not (0 <= a <= 255 and 0 <= b <= 255):
                    print("Error: valores fuera de rango (0-255)")
                    continue
                
                op = op_code
                
                # Mostrar operación
                print(f"\n→ Operación: {a} {op_symbol} {b}")
                
            except ValueError:
                print("Error: ingresa números válidos")
                continue
        else:
            print("Opción inválida")
            continue
        
        # Enviar los 3 bytes: A, B, OP
        datos = bytes([a, b, op])
        print(f"\n→ Enviando: A=0x{a:02X} ({a:3d}), B=0x{b:02X} ({b:3d}), OP=0x{op:02X}")
        
        ser.write(datos)
        time.sleep(0.05)  # Dar tiempo para procesar
        
        # Esperar respuesta
        print("→ Esperando resultado...")
        time.sleep(0.1)
        
        if ser.in_waiting > 0:
            respuesta = ser.read(ser.in_waiting)
            print(f"\n✓ Respuesta recibida ({len(respuesta)} byte(s)):")
            
            for i, byte in enumerate(respuesta):
                print(f"  Byte {i+1}: 0x{byte:02X} ({byte:3d}) = {bin(byte)[2:].zfill(8)}b")
            
            # Si es un solo byte, interpretarlo como resultado
            if len(respuesta) == 1:
                resultado = respuesta[0]
                print(f"\n→ Resultado: {resultado} (0x{resultado:02X})")
                
                # Calcular resultado esperado para verificar
                if opcion in operaciones and opcion != '9':
                    if op == 0x20:  # ADD
                        esperado = (a + b) & 0xFF
                    elif op == 0x22:  # SUB
                        esperado = (a - b) & 0xFF
                    elif op == 0x24:  # AND
                        esperado = a & b
                    elif op == 0x25:  # OR
                        esperado = a | b
                    elif op == 0x26:  # XOR
                        esperado = a ^ b
                    elif op == 0x27:  # NOR
                        esperado = ~(a | b) & 0xFF
                    elif op == 0x02:  # SRL
                        esperado = (a >> b) & 0xFF if b < 8 else 0
                    elif op == 0x03:  # SRA
                        # Shift aritmético en Python
                        if a & 0x80:  # Si es negativo
                            esperado = ((a | 0xFFFFFF00) >> b) & 0xFF if b < 8 else 0xFF
                        else:
                            esperado = (a >> b) & 0xFF if b < 8 else 0
                    
                    if resultado == esperado:
                        print(f"✓ Resultado correcto!")
                    else:
                        print(f"⚠ Esperado: {esperado} (0x{esperado:02X})")
        else:
            print("✗ No se recibió respuesta")

def modo_echo_test(ser):
    """Modo de prueba de eco (loopback)"""
    print("\n=== Modo Echo Test ===")
    print("Escribe texto y presiona Enter.")
    print("Escribe 'salir' para volver al menú.\n")
    
    while True:
        texto = input("Enviar: ")
        if texto.lower() == 'salir':
            break
        
        for char in texto:
            ser.write(char.encode('utf-8'))
            time.sleep(0.01)
            
            if ser.in_waiting > 0:
                respuesta = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
                print(f"Recibido: {respuesta} (HEX: {' '.join([f'{ord(c):02X}' for c in respuesta])})")
        
        time.sleep(0.1)
        if ser.in_waiting > 0:
            respuesta = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
            print(f"Recibido (tardío): {respuesta}")

def modo_envio_bytes(ser):
    """Enviar bytes específicos en hexadecimal"""
    print("\n=== Modo Envío de Bytes ===")
    print("Ingresa bytes en hexadecimal separados por espacio (ej: 05 0A 20)")
    print("O escribe 'salir' para volver al menú.\n")
    
    while True:
        entrada = input("Bytes (HEX): ")
        if entrada.lower() == 'salir':
            break
        
        try:
            bytes_hex = entrada.split()
            datos = bytes([int(b, 16) for b in bytes_hex])
            
            print(f"→ Enviando: {' '.join([f'{b:02X}' for b in datos])}")
            ser.write(datos)
            
            time.sleep(0.1)
            if ser.in_waiting > 0:
                respuesta = ser.read(ser.in_waiting)
                hex_resp = ' '.join([f'{b:02X}' for b in respuesta])
                print(f"← Recibido: {hex_resp}")
                for byte in respuesta:
                    print(f"   {byte:3d} (0x{byte:02X}) = {bin(byte)[2:].zfill(8)}b")
        except ValueError:
            print("Error: formato hexadecimal inválido")

def main():
    print("="*60)
    print("        UART Serial Communication - Basys 3 + ALU")
    print("="*60)
    
    puertos = listar_puertos()
    if not puertos:
        return
    
    puerto = seleccionar_puerto(puertos)
    if not puerto:
        print("Saliendo...")
        return
    
    print(f"\nConectando a {puerto}...")
    print("Configuración: 9600 baudios, 8N1")
    
    try:
        ser = serial.Serial(
            port=puerto,
            baudrate=9600,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=1
        )
        
        print(f"✓ Conectado exitosamente a {puerto}\n")
        
        while True:
            print("\n" + "="*60)
            print("                    MENÚ PRINCIPAL")
            print("="*60)
            print("1. Operaciones ALU (ADD, SUB, AND, OR, XOR, etc.)")
            print("2. Echo Test (enviar y recibir texto)")
            print("3. Enviar bytes personalizados (HEX)")
            print("4. Cambiar puerto")
            print("5. Salir")
            
            opcion = input("\nSelecciona una opción: ").strip()
            
            if opcion == '1':
                modo_alu(ser)
            elif opcion == '2':
                modo_echo_test(ser)
            elif opcion == '3':
                modo_envio_bytes(ser)
            elif opcion == '4':
                ser.close()
                return main()
            elif opcion == '5':
                break
            else:
                print("Opción inválida")
        
        ser.close()
        print("\nConexión cerrada. ¡Hasta luego!")
        
    except serial.SerialException as e:
        print(f"\n✗ Error al abrir el puerto: {e}")
        print("\nVerifica que:")
        print("- La Basys 3 esté conectada")
        print("- El puerto no esté siendo usado por otro programa")

if __name__ == "__main__":
    main()