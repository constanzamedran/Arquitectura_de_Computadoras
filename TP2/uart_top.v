// UART Top Module - Integra TX, RX y Baud Rate Generator
module uart_top #(
    parameter CLOCK_FREQ = 100000000,  // Frecuencia del clock en Hz
    parameter BAUD_RATE = 9600,        // Baud rate deseado
    parameter DATA_BITS = 8,           // Bits de datos
    parameter STOP_BITS = 1            // Bits de stop
)(
    input wire clk,
    input wire reset,
    
    // Receptor
    input wire rx,
    output wire [DATA_BITS-1:0] rx_data,
    output wire rx_done,
    
    // Transmisor
    input wire tx_start,
    input wire [DATA_BITS-1:0] tx_data,
    output wire tx,
    output wire tx_done
);

    // Señal de tick del generador de baud rate
    wire tick;
    
    // Instancia del Baud Rate Generator
    baud_rate_generator #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen (
        .clk(clk),
        .reset(reset),
        .tick(tick)
    );
    
    // Instancia del Receptor UART
    uart_rx #(
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS)
    ) receiver (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tick(tick),
        .d_out(rx_data),
        .rx_done(rx_done)
    );
    
    // Instancia del Transmisor UART
    uart_tx #(
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS)
    ) transmitter (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .tick(tick),
        .d_in(tx_data),
        .tx(tx),
        .tx_done(tx_done)
    );

endmodule