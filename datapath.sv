/* Now that all three main datapath modules are trusted to work, instantiate them in your datapath and
   add the remaining building blocks. Instantiate each of the three units (Register file 1 , ALU 2 and
   Shifter 8 ) inside datapath.sv. Note that the autograder will assume your register file has the instance
   label REGFILE (in all caps) and that the input and outputs are consistent with the way they are referenced
   in lab5_top.sv and lab5_autograder_check.sv provided in the starter repo.

   Note the autograder and lab5_top.sv require that asel, bsel and vsel are binary select inputs. Next, add 
   in the remaining logic blocks (3, 4, 5, 6, 7, 9, 10) to your datapath module using synthesizable Verilog
   that conforms to the style guidelines. Use no fewer than one always block or assign statement per hardware
   block in Figure 1. Register A, B, and C will each require an instantiated flip flop module and an assign 
   statement for the enable input in order to conform to the style guidelines. */ 

// begin top-level module!
module datapath (mdata, sximm8, sximm5, PC, clk, vsel, asel, bsel, writenum, write, readnumA, readnumB, loada, loadb, loadc, loads, shift, ALUop, Z_out, N_out, V_out, data_out, datapath_out);

    // input and output declerations for the RISC machine (may need to alter some to reg later on) 
    input [15:0] mdata, sximm8, sximm5;
    input [7:0] PC;
    input [1:0] ALUop, shift; 
    input clk, write, loada, loadb, loadc, loads, asel, bsel; // vsel, asel, bsel must be binary select 
    input [1:0] vsel;
    input [2:0] writenum, readnumA, readnumB;
    output Z_out, N_out, V_out; 
    output [15:0] datapath_out, data_out; // data_out is the output from regfile signal for readnumA, while datapath_out is the output from the whole datapath  

    // wire declerations in the RISC machine (may need to alter some to reg later on)
    wire [15:0] data_in;                    // input from REGFILE - goes into pipeline registers a and b
    wire [15:0] data_outA, data_outB;       // outputs from regfile
    wire [15:0] regAOut, regBOut;           // outputs from pipeline registers
    wire [15:0] sout;                       // output from the shifter unit
    wire [15:0] Ain, Bin;                   // outputs from the operand multiplexers - goes into ALU
    wire [15:0] ALUout;                     // output from the ALU
    wire Z, N, V;                           // output status flags from ALU

    assign data_out = data_outA;
    
    //********************************************//
    // Module instantiation guide:
    //********************************************//
    // module regfile(data_in,writenum,write,readnum,clk,data_out);
    // module alu(Ain, Bin, ALUop, Z, out);
    // module register(load, data_in, clk, out);
    // module writeBackMUX(mdata, sximm8, PC, C, vsel, data_in);
    // module sourceOperandMUX_A(RA_out, asel, Ain);
    // module sourceOperandMUX_B(sximm5, sout, bsel, Bin);
    // module shifter(sin, shift_select, sout);
    
    //instantiate the register file, ALU, and shifter unit
    /* 1 */ regfile REGFILE(data_in,writenum,write,readnumA,readnumB,clk,data_outA,data_outB);
    /* 8 */ shifter SHIFTER(regBOut, shift, sout);
    /* 6 */ sourceOperandMUX_A SOURCE_A(regAOut, asel, Ain);
    /* 7 */ sourceOperandMUX_B SOURCE_B(sximm5, sout, bsel, Bin);
    /* 2 */ ALU ALU(Ain, Bin, ALUop, ALUout, Z, N, V);
            register PIPELINE_A(loada, data_outA, clk, regAOut);
            register PIPELINE_B(loadb, data_outB, clk, regBOut);
    /* 5 */ register PIPELINE_C(loadc, ALUout, clk, datapath_out);
    /* 10*/ statusRegister STATUS_REGISTER(loads, Z, N, V, clk, Z_out, N_out, V_out); 
    /* 9 */ writeBackMUX WRITEBACK(mdata, sximm8, PC, datapath_out, vsel, data_in);
    
    //note that the Z,N,V outputs from the status register are sandwhiched together as a single 3 bit value

endmodule

// begin additional modules

//datapath_in/out is the I/O of the entire module
//vsel is a select
//data_in is the input into regfile
module writeBackMUX(mdata, sximm8, PC, datapath_out, vsel, data_in);
  input [15:0] mdata, sximm8, datapath_out;
  input [7:0] PC;
  input [1:0] vsel;
  output reg [15:0] data_in;

  always_comb begin
    case (vsel)
      2'b00 : data_in = mdata;
      2'b01 : data_in = sximm8;
      2'b10 : data_in = {8'b0, PC};
      2'b11 : data_in = datapath_out;
      default : data_in = 8'bxxxxxxxx;
    endcase
  end
endmodule

//RA_out is the output from Pipeline Register A
//asel is a select
module sourceOperandMUX_A(RA_out, asel, Ain);
  input [15:0] RA_out;
  input asel;
  output [15:0] Ain;

  assign Ain = (asel ? 16'd0 : RA_out);
endmodule

//sout is the output from the Shifter
module sourceOperandMUX_B(sximm5, sout, bsel, Bin);
  input [15:0] sximm5, sout;
  input bsel;
  output [15:0] Bin;

  assign Bin = (bsel ? sximm5 : sout);
endmodule

module statusRegister(load, Z, N, V, clk, Z_out, N_out, V_out);

    input load;
    input Z, N, V;
    input clk;
    output reg Z_out,N_out,V_out;

    wire D1;
    wire D2;
    wire D3;

    assign D1 = (load ? Z : Z_out);
    assign D2 = (load ? N : N_out);
    assign D3 = (load ? V : V_out);

    vDFF #(1) flipflopZ(clk, D1, Z_out);
    vDFF #(1) flipflopN(clk, D2, N_out);
    vDFF #(1) flipflopV(clk, D3, V_out);

endmodule 

//including vDFF for the purpose of initial testbench of datapath - remove when testing with lab7_top.sv
/*
module vDFF(clk,D,Q);

    parameter n=1;
    input clk;
    input [n-1:0] D;
    output [n-1:0] Q;
    reg [n-1:0] Q;

    always @(posedge clk)
      Q <= D;
      
endmodule
*/
