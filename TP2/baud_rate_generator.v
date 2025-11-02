// Baud Rate Generator
// Genera un tick 16 veces por baud rate
module baud_rate_generator #(
    parameter CLOCK_FREQ = 50000000,  // 50 MHz
    parameter BAUD_RATE = 19200
)(
    input wire clk,
    input wire reset,
    output reg tick
);
    // Calcular el divisor: Clock / (BaudRate * 16)
    localparam DIVISOR = CLOCK_FREQ / (BAUD_RATE * 16);
    
    // Contador
    reg [$clog2(DIVISOR)-1:0] counter;
    
    always @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            tick <= 0;
        end
        else begin
            if (counter == DIVISOR - 1) begin
                counter <= 0;
                tick <= 1;
            end
            else begin
                counter <= counter + 1;
                tick <= 0;
            end
        end
    end
endmodule