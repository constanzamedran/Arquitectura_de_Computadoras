import time

# Intentar importar pyserial y dar mensaje instructivo si falta
try:
    import serial
    import serial.tools.list_ports
except ModuleNotFoundError:
    # Mensaje claro para el usuario en Windows/Linux/Mac
    print("\nEl módulo 'pyserial' no está instalado. Instálalo con:")
    print("  python -m pip install pyserial")
    print("o si usas un entorno virtual: pip install pyserial\n")
    # Volvemos a lanzar la excepción para que el stack trace sea visible si el usuario lo quiere
    raise

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

def modo_echo_test(ser):
    """Modo de prueba de eco (loopback)"""
    print("\n=== Modo Echo Test ===")
    print("Escribe texto y presiona Enter. El texto se enviará y deberías recibirlo de vuelta.")
    print("Escribe 'salir' para volver al menú.\n")
    
    while True:
        texto = input("Enviar: ")
        if texto.lower() == 'salir':
            break
        
        # Enviar cada carácter
        for char in texto:
            ser.write(char.encode('utf-8'))
            time.sleep(0.01)  # Pequeña pausa entre caracteres
            
            # Intentar leer la respuesta
            if ser.in_waiting > 0:
                respuesta = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
                print(f"Recibido: {respuesta} (ASCII: {[ord(c) for c in respuesta]})")
        
        # Esperar un poco más por si hay datos retrasados
        time.sleep(0.1)
        if ser.in_waiting > 0:
            respuesta = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
            print(f"Recibido (tardío): {respuesta}")

def modo_monitor(ser):
    """Modo monitor continuo"""
    print("\n=== Modo Monitor Continuo ===")
    print("Monitoreando datos entrantes... (Ctrl+C para detener)\n")
    
    try:
        while True:
            if ser.in_waiting > 0:
                datos = ser.read(ser.in_waiting)
                # Mostrar como texto y como hexadecimal
                texto = datos.decode('utf-8', errors='ignore')
                hex_str = ' '.join([f'{b:02X}' for b in datos])
                print(f"RX: {texto} (HEX: {hex_str})")
            time.sleep(0.01)
    except KeyboardInterrupt:
        print("\nMonitor detenido")

def modo_envio_bytes(ser):
    """Enviar bytes específicos en hexadecimal"""
    print("\n=== Modo Envío de Bytes ===")
    print("Ingresa bytes en hexadecimal separados por espacio (ej: 41 42 43)")
    print("O escribe 'salir' para volver al menú.\n")
    
    while True:
        entrada = input("Bytes (HEX): ")
        if entrada.lower() == 'salir':
            break
        
        try:
            # Convertir entrada hexadecimal a bytes
            bytes_hex = entrada.split()
            datos = bytes([int(b, 16) for b in bytes_hex])
            
            print(f"Enviando: {' '.join([f'{b:02X}' for b in datos])}")
            ser.write(datos)
            
            # Esperar respuesta
            time.sleep(0.1)
            if ser.in_waiting > 0:
                respuesta = ser.read(ser.in_waiting)
                hex_resp = ' '.join([f'{b:02X}' for b in respuesta])
                texto_resp = respuesta.decode('utf-8', errors='ignore')
                print(f"Recibido: {hex_resp} (ASCII: {texto_resp})")
        except ValueError:
            print("Error: formato hexadecimal inválido")

def main():
    print("=" * 50)
    print("    UART Serial Communication - Basys 3")
    print("=" * 50)
    
    # Listar puertos disponibles
    puertos = listar_puertos()
    if not puertos:
        return
    
    # Seleccionar puerto
    puerto = seleccionar_puerto(puertos)
    if not puerto:
        print("Saliendo...")
        return
    
    # Configurar comunicación serial
    print(f"\nConectando a {puerto}...")
    print("Configuración: 9600 baudios, 8N1")
    
    try:
        ser = serial.Serial(
            port=puerto,
            baudrate=9600,      # Mismo baud rate que en uart_test_top.v
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=1
        )
        
        print(f"✓ Conectado exitosamente a {puerto}\n")
        
        # Menú principal
        while True:
            print("\n" + "=" * 50)
            print("MENÚ PRINCIPAL")
            print("=" * 50)
            print("1. Echo Test (enviar y recibir texto)")
            print("2. Monitor continuo (solo recibir)")
            print("3. Enviar bytes específicos (HEX)")
            print("4. Cambiar puerto")
            print("5. Salir")
            
            opcion = input("\nSelecciona una opción: ")
            
            if opcion == '1':
                modo_echo_test(ser)
            elif opcion == '2':
                modo_monitor(ser)
            elif opcion == '3':
                modo_envio_bytes(ser)
            elif opcion == '4':
                ser.close()
                return main()  # Reiniciar para seleccionar nuevo puerto
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
        print("- Tengas permisos para acceder al puerto (en Linux: sudo)")

if __name__ == "__main__":
    main()