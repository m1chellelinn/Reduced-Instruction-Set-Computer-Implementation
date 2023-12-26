module regfile(data_in,writenum,write,readnumA,readnumB,clk,data_outA,data_outB);

    input [15:0] data_in;
    input [2:0] writenum, readnumA, readnumB;
    input write, clk;
    output [15:0] data_outA, data_outB;
    // fill out the rest

    wire [7:0] decOut1; 
    wire [7:0] selectA, selectB;
    wire [7:0] load;

    //Define register signals
    reg [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
   
    //Instantiatate write and read decoders //
    decoder38 DEC1(writenum, decOut1);
    decoder38 DEC2(readnumA, selectA);
    decoder38 DEC3(readnumB, selectB);

    //Assign load based on output of top decoder and input write
    assign load = (decOut1 & {8{write}});

    //Register instantiations
    register Reg0(load[0], data_in, clk, R0);
    register Reg1(load[1], data_in, clk, R1);
    register Reg2(load[2], data_in, clk, R2);
    register Reg3(load[3], data_in, clk, R3);
    register Reg4(load[4], data_in, clk, R4);
    register Reg5(load[5], data_in, clk, R5);
    register Reg6(load[6], data_in, clk, R6);
    register Reg7(load[7], data_in, clk, R7);

    //Instantiate MUX
    oneHot81Mux READNUM_A(R0,R1,R2,R3,R4,R5,R6,R7,selectA,data_outA);
    oneHot81Mux READNUM_B(R0,R1,R2,R3,R4,R5,R6,R7,selectB,data_outB);


endmodule


module decoder38(decIn, decOut);
    input [2:0] decIn;
    output[7:0] decOut;

    wire [7:0] decOut = 1'b1 << decIn; 
endmodule

module oneHot81Mux (register0, register1, register2, register3, register4, register5, register6, register7, select, out);

    input [15:0] register0, register1, register2, register3, 
                 register4, register5, register6, register7;
    input [7:0] select;
    output reg [15:0] out;

    //Chooses the signal to output based on the "select" signal
    always_comb begin
        case(select)
        8'b00000001: out = register0;
        8'b00000010: out = register1;
        8'b00000100: out = register2;
        8'b00001000: out = register3;
        8'b00010000: out = register4;
        8'b00100000: out = register5;
        8'b01000000: out = register6;
        8'b10000000: out = register7;
        default: out = 16'bxxxxxxxxxxxxxxxx;
        endcase
    end
endmodule

//Register module for all the "register" components (not just in the regfile)
module register(load, data_in, clk, out);
    parameter bits = 16;

    input load;
    input [bits-1:0] data_in;
    input clk;
    output reg [bits-1:0] out;

    wire [bits-1:0] D;

    assign D  = (load ? data_in : out);

    vDFF #(bits) flipflop(clk, D, out);
endmodule


module vDFF(clk,D,Q);

    parameter n=1;
    input clk;
    input [n-1:0] D;
    output [n-1:0] Q;
    reg [n-1:0] Q;

    always @(posedge clk)
        Q <= D;

endmodule
