`timescale 1ns / 1ps

module testbench_alu;
    parameter N = 8;
    
    reg  [N-1:0] A, B;
    reg  [5:0] Op;
    wire [N-1:0] Result;
    reg  [N-1:0] Expected;
    integer errors = 0;
    
    // Instancia de la ALU
    alu #(.N(N)) uut (
        .A(A),
        .B(B),
        .Op(Op),
        .Result(Result)
    );
    
    // Task para verificar resultados
    task check_result;
        input [N-1:0] exp;
        begin
            #1;
            if (Result !== exp) begin
                $display("ERROR: A=%d, B=%d, Op=%b | Expected=%d, Got=%d", 
                         A, B, Op, exp, Result);
                errors = errors + 1;
            end else begin
                $display("OK: A=%d, B=%d, Op=%b | Result=%d", A, B, Op, Result);
            end
        end
    endtask
    
    initial begin
        $display("=== Iniciando Test de ALU ===");
        
        // Pruebas dirigidas
        A = 8'd10; B = 8'd5; Op = 6'b100000; #10; check_result(8'd15);  // ADD
        A = 8'd10; B = 8'd5; Op = 6'b100010; #10; check_result(8'd5);   // SUB
        A = 8'b11110000; B = 8'b10101010; Op = 6'b100100; #10; 
        check_result(8'b10100000);  // AND
        
        A = 8'b11110000; B = 8'b10101010; Op = 6'b100101; #10; 
        check_result(8'b11111010);  // OR
        
        A = 8'b11110000; B = 8'b10101010; Op = 6'b100110; #10; 
        check_result(8'b01011010);  // XOR
        
        A = 8'b11110000; B = 8'b10101010; Op = 6'b100111; #10; 
        check_result(8'b00000101);  // NOR
        
        A = 8'b11110000; B = 8'd2; Op = 6'b000010; #10; 
        check_result(8'b00111100);  // SRL
        
        A = 8'b11110000; B = 8'd2; Op = 6'b000011; #10; 
        check_result(8'b11111100);  // SRA
        
        // Pruebas aleatorias
        $display("\n=== Pruebas Aleatorias ===");
        repeat(20) begin
            A = $random;
            B = $random % 8;  // Limitar B para shifts
            Op = {$random} % 8;  // Ciclar entre operaciones principales
            case (Op[2:0])
                3'd0: Op = 6'b100000;  // ADD
                3'd1: Op = 6'b100010;  // SUB
                3'd2: Op = 6'b100100;  // AND
                3'd3: Op = 6'b100101;  // OR
                3'd4: Op = 6'b100110;  // XOR
                3'd5: Op = 6'b100111;  // NOR
                3'd6: Op = 6'b000010;  // SRL
                3'd7: Op = 6'b000011;  // SRA
            endcase
            
            #10;
            // Calcular resultado esperado
            case (Op)
                6'b100000: Expected = A + B;
                6'b100010: Expected = A - B;
                6'b100100: Expected = A & B;
                6'b100101: Expected = A | B;
                6'b100110: Expected = A ^ B;
                6'b100111: Expected = ~(A | B);
                6'b000010: Expected = A >> B[2:0];
                6'b000011: Expected = $signed(A) >>> B[2:0];
                default:   Expected = 0;
            endcase
            check_result(Expected);
        end
        
        $display("\n=== Test Finalizado ===");
        $display("Total de errores: %d", errors);
        if (errors == 0)
            $display("*** TODOS LOS TESTS PASARON ***");
        else
            $display("*** FALLARON %d TESTS ***", errors);
            
        $finish;
    end
    
endmodule