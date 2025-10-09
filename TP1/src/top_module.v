`timescale 1ns / 1ps

module topmodule (
    input         CLK,          // clock de 100MHz
    input  [7:0] SW,           // 8 switches (SW0-SW7)
    input         BTN_A,        // botón para cargar A
    input         BTN_B,        // botón para cargar B  
    input         BTN_OP,       // botón para cargar Op
    input         BTN_RESET,    // botón para reset
    output [7:0]  LED,          // LEDs para mostrar resultado
    output        LED_ZERO,     // LED para flag Zero
    output        LED_CARRY     // LED para flag Carry
);

    // Registros internos
    reg [7:0] A, B;
    reg [5:0] Op;
    wire [7:0] Result;
    wire Zero, Carry;
    
    // Sincronización de botones (anti-rebote simple)
    reg [1:0] btn_a_sync, btn_b_sync, btn_op_sync, btn_reset_sync;
    wire btn_a_pulse, btn_b_pulse, btn_op_pulse, btn_reset_pulse;
    
    // Sincronizar botones con el clock
    always @(posedge CLK) begin
        btn_a_sync     <= {btn_a_sync[0], BTN_A};
        btn_b_sync     <= {btn_b_sync[0], BTN_B};
        btn_op_sync    <= {btn_op_sync[0], BTN_OP};
        btn_reset_sync <= {btn_reset_sync[0], BTN_RESET};
    end
    
    // Detectar flanco de subida
    assign btn_a_pulse     = btn_a_sync[0]     & ~btn_a_sync[1];
    assign btn_b_pulse     = btn_b_sync[0]     & ~btn_b_sync[1];
    assign btn_op_pulse    = btn_op_sync[0]    & ~btn_op_sync[1];
    assign btn_reset_pulse = btn_reset_sync[0] & ~btn_reset_sync[1];
    
    // Cargar valores cuando se presionan los botones
    always @(posedge CLK) begin
        if (btn_reset_pulse) begin
            // RESET: limpiar todos los registros
            A  <= 8'd0;
            B  <= 8'd0;
            Op <= 6'd0;
        end else begin
            if (btn_a_pulse)  A  <= SW[7:0];    // SW0-SW7 → A
            if (btn_b_pulse)  B  <= SW[7:0];    // SW0-SW7 → B
            if (btn_op_pulse) Op <= SW[5:0];    // SW0-SW5 → Op
        end
    end
    
    // Instancia de la ALU
    alu #(.N(8)) alu_inst (
        .A(A),
        .B(B),
        .Op(Op),
        .Result(Result),
        .Zero(Zero),
        .Carry(Carry)
    );
    
    // Mostrar resultado en LEDs
    assign LED = Result;
    assign LED_ZERO = Zero;      // LED se enciende cuando resultado = 0
    assign LED_CARRY = Carry;    // LED se enciende cuando hay carry/overflow
    
endmodule

