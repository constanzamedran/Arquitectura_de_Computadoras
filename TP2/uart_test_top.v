// ALU UART Top - Integra ALU con UART
// Protocolo: Recibe 3 bytes [A] [B] [OP], calcula, muestra en LEDs/7seg y envía resultado
module alu_uart_top (
    input wire clk,              // Clock 100 MHz de Basys 3
    input wire btnC,             // Botón central como reset
    
    // UART
    input wire RsRx,             // RX (recibe desde PC)
    output wire RsTx,            // TX (envía a PC)
    
    // Visualización
    output wire [15:0] led,      // 16 LEDs
    output wire [6:0] seg,       // 7 segmentos
    output wire [3:0] an         // Ánodos 7 segmentos
);

    // Señales internas del UART
    wire [7:0] rx_data;
    wire rx_done;
    wire tx_done;
    
    // Control de transmisión
    reg tx_start;
    reg [7:0] tx_data;
    
    // Registros para operandos y operación
    reg [7:0] operand_A;
    reg [7:0] operand_B;
    reg [5:0] operation;
    
    // Resultado de la ALU
    wire [7:0] alu_result;
    wire alu_zero;
    wire alu_carry;
    
    // Instancia del UART
    uart_top #(
        .CLOCK_FREQ(100000000),  // 100 MHz
        .BAUD_RATE(9600),
        .DATA_BITS(8),
        .STOP_BITS(1)
    ) uart (
        .clk(clk),
        .reset(btnC),
        .rx(RsRx),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(RsTx),
        .tx_done(tx_done)
    );
    
    // Instancia de la ALU
    alu #(
        .N(8)
    ) alu_inst (
        .A(operand_A),
        .B(operand_B),
        .Op(operation),
        .Result(alu_result),
        .Zero(alu_zero),
        .Carry(alu_carry)
    );
    
    // FSM para recibir datos y enviar resultado
    localparam WAIT_A    = 3'b000;  // Esperar operando A
    localparam WAIT_B    = 3'b001;  // Esperar operando B
    localparam WAIT_OP   = 3'b010;  // Esperar operación
    localparam COMPUTE   = 3'b011;  // Calcular (dar tiempo a la ALU)
    localparam SEND      = 3'b100;  // Enviar resultado
    localparam WAIT_SEND = 3'b101;  // Esperar fin de transmisión
    
    reg [2:0] state, next_state;
    
    // Registro de estado (Memory)
    always @(posedge clk) begin
        if (btnC)
            state <= WAIT_A;
        else
            state <= next_state;
    end
    
    // Lógica de próximo estado
    always @(*) begin
        case (state)
            WAIT_A: begin
                if (rx_done)
                    next_state = WAIT_B;
                else
                    next_state = WAIT_A;
            end
            
            WAIT_B: begin
                if (rx_done)
                    next_state = WAIT_OP;
                else
                    next_state = WAIT_B;
            end
            
            WAIT_OP: begin
                if (rx_done)
                    next_state = COMPUTE;
                else
                    next_state = WAIT_OP;
            end
            
            COMPUTE: begin
                // Dar un ciclo para que la ALU compute (es combinacional pero por seguridad)
                next_state = SEND;
            end
            
            SEND: begin
                next_state = WAIT_SEND;
            end
            
            WAIT_SEND: begin
                if (tx_done)
                    next_state = WAIT_A;  // Volver a esperar nueva operación
                else
                    next_state = WAIT_SEND;
            end
            
            default: next_state = WAIT_A;
        endcase
    end
    
    // Lógica de operaciones (secuencial)
    always @(posedge clk) begin
        if (btnC) begin
            tx_start <= 0;
            tx_data <= 0;
            operand_A <= 0;
            operand_B <= 0;
            operation <= 0;
        end
        else begin
            tx_start <= 0;  // Por defecto
            
            case (state)
                WAIT_A: begin
                    if (rx_done) begin
                        operand_A <= rx_data;
                    end
                end
                
                WAIT_B: begin
                    if (rx_done) begin
                        operand_B <= rx_data;
                    end
                end
                
                WAIT_OP: begin
                    if (rx_done) begin
                        operation <= rx_data[5:0];
                    end
                end
                
                COMPUTE: begin
                    // La ALU ya tiene el resultado
                end
                
                SEND: begin
                    tx_data <= alu_result;
                    tx_start <= 1;
                end
                
                WAIT_SEND: begin
                    // Esperar a que termine la transmisión
                end
                
                default: begin
                    tx_start <= 0;
                end
            endcase
        end
    end
    
    // ====================================================================
    // VISUALIZACIÓN EN LEDs
    // ====================================================================
    // LEDs 0-7: Resultado de la ALU
    assign led[7:0] = alu_result;
    
    // LEDs 8-13: Apagados o para propósito general
    assign led[8] = (state == WAIT_B);   // Indica que recibió A, esperando B
    assign led[9] = (state == WAIT_OP);  // Indica que recibió A y B, esperando OP
    assign led[10] = (state == COMPUTE || state == SEND || state == WAIT_SEND);  // Calculando/Enviando
    assign led[11] = rx_done;            // Pulsó cuando recibe un byte
    assign led[12] = (state == SEND || state == WAIT_SEND);  // Transmitiendo
    assign led[13] = 1'b0;               // Apagado
    
    // LED 14: Flag Carry de la ALU
    assign led[14] = alu_carry;
    
    // LED 15: Flag Zero de la ALU
    assign led[15] = alu_zero;
    
    // ====================================================================
    // DISPLAY DE 7 SEGMENTOS
    // ====================================================================
    // Display 0-1 (derecha): Operando B, luego Resultado
    // Display 2-3 (izquierda): Operando A, luego se apagan
    
    wire [3:0] op_a_high = operand_A[7:4];
    wire [3:0] op_a_low = operand_A[3:0];
    wire [3:0] op_b_high = operand_B[7:4];
    wire [3:0] op_b_low = operand_B[3:0];
    wire [3:0] result_high = alu_result[7:4];
    wire [3:0] result_low = alu_result[3:0];
    
    // Contador para multiplexar los displays
    reg [19:0] refresh_counter;
    always @(posedge clk) begin
        if (btnC)
            refresh_counter <= 0;
        else
            refresh_counter <= refresh_counter + 1;
    end
    
    wire [1:0] display_select = refresh_counter[19:18];
    
    // Selección de display activo
    reg [3:0] current_digit;
    always @(*) begin
        case (display_select)
            2'b00: begin
                // Display 0 (derecha más a la derecha)
                if (state == COMPUTE || state == SEND || state == WAIT_SEND)
                    current_digit = result_low;  // Mostrar resultado bajo
                else
                    current_digit = op_b_low;  // Mostrar B bajo (o 0 si no hay B aún)
            end
            2'b01: begin
                // Display 1 (derecha más a la izquierda)
                if (state == COMPUTE || state == SEND || state == WAIT_SEND)
                    current_digit = result_high;  // Mostrar resultado alto
                else
                    current_digit = op_b_high;  // Mostrar B alto (o 0 si no hay B aún)
            end
            2'b10: begin
                // Display 2 (izquierda más a la derecha)
                current_digit = op_a_low;  // Siempre mostrar A bajo
            end
            2'b11: begin
                // Display 3 (izquierda más a la izquierda)
                current_digit = op_a_high;  // Siempre mostrar A alto
            end
        endcase
    end
    
    // Decodificador BCD a 7 segmentos (cátodo común)
    reg [6:0] seg_decode;
    always @(*) begin
        case (current_digit)
            4'h0: seg_decode = 7'b1000000; // 0
            4'h1: seg_decode = 7'b1111001; // 1
            4'h2: seg_decode = 7'b0100100; // 2
            4'h3: seg_decode = 7'b0110000; // 3
            4'h4: seg_decode = 7'b0011001; // 4
            4'h5: seg_decode = 7'b0010010; // 5
            4'h6: seg_decode = 7'b0000010; // 6
            4'h7: seg_decode = 7'b1111000; // 7
            4'h8: seg_decode = 7'b0000000; // 8
            4'h9: seg_decode = 7'b0010000; // 9
            4'hA: seg_decode = 7'b0001000; // A
            4'hB: seg_decode = 7'b0000011; // b
            4'hC: seg_decode = 7'b1000110; // C
            4'hD: seg_decode = 7'b0100001; // d
            4'hE: seg_decode = 7'b0000110; // E
            4'hF: seg_decode = 7'b0001110; // F
            default: seg_decode = 7'b1111111; // Apagado
        endcase
    end
    
    assign seg = seg_decode;
    
    // Control de ánodos (activo bajo)
    reg [3:0] an_decode;
    always @(*) begin
        if (state == COMPUTE || state == SEND || state == WAIT_SEND) begin
            // Después del cálculo, apagar displays izquierdos (2 y 3)
            case (display_select)
                2'b00: an_decode = 4'b1110;  // Display 0 activo (Resultado bajo)
                2'b01: an_decode = 4'b1101;  // Display 1 activo (Resultado alto)
                2'b10: an_decode = 4'b1111;  // Display 2 apagado
                2'b11: an_decode = 4'b1111;  // Display 3 apagado
            endcase
        end
        else begin
            // Mostrar todos los displays
            case (display_select)
                2'b00: an_decode = 4'b1110;  // Display 0 activo
                2'b01: an_decode = 4'b1101;  // Display 1 activo
                2'b10: an_decode = 4'b1011;  // Display 2 activo
                2'b11: an_decode = 4'b0111;  // Display 3 activo
            endcase
        end
    end
    
    assign an = an_decode;

endmodule