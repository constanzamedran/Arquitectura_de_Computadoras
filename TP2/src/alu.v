 `timescale 1ns / 1ps

module alu #(
    parameter N = 8
)(
    input  [N-1:0] A,
    input  [N-1:0] B,
    input  [5:0] Op,
    output reg [N-1:0] Result,
    output reg Zero,       // Flag: resultado es cero
    output reg Carry       // Flag: hubo acarreo/overflow
);

reg [N:0] temp_result;  // N+1 bits para detectar carry


// Número de bits necesarios para representar desplazamientos de 0..N-1
localparam SHIFT_BITS = $clog2(N);


always @(*) begin
    Carry = 0;  // Por defecto no hay carry
    
    case (Op)
        6'b100000: begin  // ADD
            temp_result = A + B;
            Result = temp_result[N-1:0];
            Carry = temp_result[N];  // Bit de carry
        end
        
        6'b100010: begin  // SUB
            temp_result = A - B;
            Result = temp_result[N-1:0];
            Carry = temp_result[N];  // Borrow (préstamo)
        end
        
        6'b100100: Result = A & B;                    // AND
        6'b100101: Result = A | B;                    // OR
        6'b100110: Result = A ^ B;                    // XOR
        6'b100111: Result = ~(A | B);                 // NOR
        6'b000010: Result = A >> B[SHIFT_BITS-1:0];   //SRL
        6'b000011: Result = $signed(A) >>> B[SHIFT_BITS-1:0];    // SRA
        default:   Result = {N{1'b0}};               //por las dudas
    endcase
    
    // Flag Zero: se activa cuando el resultado es 0
    Zero = (Result == {N{1'b0}});
end

endmodule

