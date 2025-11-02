// UART Transmitter
module uart_tx #(
    parameter DATA_BITS = 8,
    parameter STOP_BITS = 1
)(
    input wire clk,
    input wire reset,
    input wire tx_start,     // Señal para iniciar transmisión
    input wire tick,         // Tick del baud rate generator (16x)
    input wire [DATA_BITS-1:0] d_in,  // Datos a transmitir
    output reg tx,           // Señal serial de salida
    output reg tx_done       // Señal de transmisión completa
);

    // Estados (One-Hot encoding)
    localparam IDLE  = 3'b001;
    localparam START = 3'b010;
    localparam DATA  = 3'b100;
    
    // Variables de estado
    reg [2:0] state, next_state;
    
    // Registros internos
    reg [3:0] tick_counter;     // Contador de ticks (0-15)
    reg [3:0] bit_counter;      // Contador de bits
    reg [DATA_BITS-1:0] shift_reg; // Shift register para datos
    
    // Registro de estado (Memory)
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Lógica de próximo estado (Next-state logic)
    always @(*) begin
        case (state)
            IDLE: begin
                if (tx_start)
                    next_state = START;
                else
                    next_state = IDLE;
            end
            
            START: begin
                if (tick && tick_counter == 15)
                    next_state = DATA;
                else
                    next_state = START;
            end
            
            DATA: begin
                if (tick && tick_counter == 15 && bit_counter == DATA_BITS + STOP_BITS - 1)
                    next_state = IDLE;
                else
                    next_state = DATA;
            end
            
            default: next_state = IDLE; // Fault recovery
        endcase
    end
    
    // Lógica de operaciones (secuencial)
    always @(posedge clk) begin
        if (reset) begin
            tick_counter <= 0;
            bit_counter <= 0;
            shift_reg <= 0;
            tx_done <= 0;
            tx <= 1; // Línea en alto cuando está idle
        end
        else begin
            tx_done <= 0; // Por defecto
            
            case (state)
                IDLE: begin
                    tx <= 1; // Línea en alto
                    tick_counter <= 0;
                    bit_counter <= 0;
                    if (tx_start) begin
                        shift_reg <= d_in; // Cargar datos
                    end
                end
                
                START: begin
                    tx <= 0; // Bit de Start
                    if (tick) begin
                        if (tick_counter == 15) begin
                            tick_counter <= 0;
                        end
                        else begin
                            tick_counter <= tick_counter + 1;
                        end
                    end
                end
                
                DATA: begin
                    if (tick) begin
                        if (tick_counter == 15) begin
                            tick_counter <= 0;
                            bit_counter <= bit_counter + 1;
                            
                            if (bit_counter < DATA_BITS) begin
                                // Enviar bits de datos (LSB primero)
                                tx <= shift_reg[0];
                                shift_reg <= {1'b1, shift_reg[DATA_BITS-1:1]};
                            end
                            else begin
                                // Bits de Stop
                                tx <= 1;
                            end
                            
                            // Señal de finalización
                            if (bit_counter == DATA_BITS + STOP_BITS - 1) begin
                                tx_done <= 1;
                            end
                        end
                        else begin
                            tick_counter <= tick_counter + 1;
                        end
                    end
                    else begin
                        // Mantener el valor actual entre ticks
                        if (bit_counter < DATA_BITS)
                            tx <= shift_reg[0];
                        else
                            tx <= 1;
                    end
                end
                
                default: begin
                    tx <= 1;
                    tick_counter <= 0;
                    bit_counter <= 0;
                end
            endcase
        end
    end

endmodule