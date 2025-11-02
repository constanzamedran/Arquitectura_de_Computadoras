// UART Receiver
module uart_rx #(
    parameter DATA_BITS = 8,
    parameter STOP_BITS = 1
)(
    input wire clk,
    input wire reset,
    input wire rx,           // Señal serial de entrada
    input wire tick,         // Tick del baud rate generator (16x)
    output reg [DATA_BITS-1:0] d_out,  // Datos recibidos
    output reg rx_done       // Señal de recepción completa
);

    // Estados (One-Hot encoding)
    localparam IDLE  = 3'b001;
    localparam START = 3'b010;
    localparam DATA  = 3'b100;
    
    // Variables de estado
    reg [2:0] state, next_state;
    
    // Registros internos
    reg [3:0] tick_counter;     // Contador de ticks (0-15)
    reg [3:0] bit_counter;      // Contador de bits de datos (ampliado para incluir stop)
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
                if (rx == 0) // Detecta bit de Start
                    next_state = START;
                else
                    next_state = IDLE;
            end
            
            START: begin
                if (tick && tick_counter == 7)
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
            rx_done <= 0;
            d_out <= 0;
        end
        else begin
            rx_done <= 0; // Por defecto, solo pulsa por un ciclo
            
            case (state)
                IDLE: begin
                    tick_counter <= 0;
                    bit_counter <= 0;
                end
                
                START: begin
                    if (tick) begin
                        if (tick_counter == 7) begin
                            // Punto medio del bit de Start verificado
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
                            // Punto medio del bit
                            tick_counter <= 0;
                            
                            if (bit_counter < DATA_BITS) begin
                                // Recibir bits de datos (LSB primero)
                                shift_reg <= {rx, shift_reg[DATA_BITS-1:1]};
                            end
                            
                            bit_counter <= bit_counter + 1;
                            
                            // Cuando terminamos todos los bits (datos + stop)
                            if (bit_counter == DATA_BITS + STOP_BITS - 1) begin
                                d_out <= shift_reg;
                                rx_done <= 1;
                            end
                        end
                        else begin
                            tick_counter <= tick_counter + 1;
                        end
                    end
                end
                
                default: begin
                    tick_counter <= 0;
                    bit_counter <= 0;
                end
            endcase
        end
    end

endmodule