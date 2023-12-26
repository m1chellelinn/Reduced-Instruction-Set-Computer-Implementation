module instruction(in, nselA, nselB, ALUop, sximm5, sximm8, shift, readnumA, readnumB, writenum, opcode, op, cond, sximm8_pc);

    input [15:0] in;
    input [2:0] nselA, nselB; 
    output [1:0] ALUop, shift, op;
    output [2:0] writenum, readnumA, readnumB, opcode, cond;
    output [8:0] sximm8_pc;
    output [15:0] sximm5, sximm8; //immediate values to be sign extended to 16 bits

    //additional signals
    wire [2:0] Rn, Rd, Rm;

    assign Rn = in [10:8];
    assign Rd = in [7:5];
    assign Rm = in [2:0];

    //one hot select mux to drive appropriate register to readnum and writenum
    assign readnumA = ((nselA == 3'b001) ? Rn : ((nselA == 3'b010) ? Rd : Rm));
    assign readnumB = ((nselB == 3'b001) ? Rn : ((nselB == 3'b010) ? Rd : Rm));
    assign writenum = ((nselA == 3'b001) ? Rn : ((nselA == 3'b010) ? Rd : Rm));

    //sign extending sximm5 and sximm8 using the $signed function
    assign sximm5 = $signed({ {11{in[4]}}, in[4:0] });
    assign sximm8 = $signed({ {8{in[7]}}, in[7:0] });
    assign sximm8_pc = $signed( { in[7], in [7:0]} );

    //additional output assignments
    assign ALUop = in [12:11];
    assign opcode = in [15:13];
    assign op = in [12:11];
    assign cond = in [10:8];
    //if instruction is STR, set shift to 00, otherwise set shift as based on the encoding as usual  
    //assign shift = (opcode[2] ? (opcode[1] ? in[4:3] : (opcode[0] ? in[4:3] : 2'b00)) : in [4:3]);
    assign shift = (opcode[2:0] == 3'b100) ? (2'b00) : (in [4:3]);
    
endmodule


