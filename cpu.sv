module cpu(clk, reset, read_data, write_data, mem_addr, mem_cmd, LEDR8);

    input clk, reset;
    input [15:0] read_data;
    output [15:0] write_data;
    output [8:0] mem_addr;
    output [1:0] mem_cmd; 
    output LEDR8;

    //********************************************//
    // Module & wire instantiation guide:
    //********************************************//
    //module register(load, data_in, clk, out);
    //module instruction(in, nsel, ALUop, sximm5, sximm8, shift, readnum, writenum, opcode, op);
    //module controller(reset, clk, opcode, op, nsel, out_to_datapath, out_to_memory);
    //module datapath (mdata, sximm8, sximm5, PC, clk, vsel, asel, bsel, writenum, write, readnum, 
    //                 loada, loadb, loadc, loads, shift, ALUop, Z_out, N_out, V_out, datapath_out);
    //module PCAddress(clk, load_pc, reset_pc, load_addr, addr_sel, write_data, mem_addr);
    //
    //out_to_datapath = { write, vsel[1], vsel[0], loada, loadb, asel, bsel, loadc, loads} 
    //out_to_memory = {reset_pc, load_pc, load_ir, load_addr, addr_sel, mem_cmd}

    //instantiation of the instruction register
    wire load_ir;
    wire [15:0] read_data;
    wire [15:0] decoder_in; 
    register InstructionRegister(load_ir, read_data, clk, decoder_in);

    //instantiation of the instruction decoder
    wire [2:0] nselA, nselB, readnumA, readnumB, writenum, opcode, cond;
    wire [1:0] ALUop, shift, op;
    wire [8:0] sximm8_pc;
    wire [15:0] sximm5, sximm8;
    instruction InstructionDecoder(decoder_in, nselA, nselB, ALUop, sximm5, sximm8, shift, readnumA, readnumB, writenum, opcode, op, cond, sximm8_pc);

    //instantiation of the controller
    wire [8:0] out_to_datapath;
    wire [6:0] out_to_memory;
    wire N, V, Z;
    wire [1:0] select_pc; 
    controller ControllerFSM(reset, clk, opcode, op, cond, Z, N, V, nselA, nselB, out_to_datapath, out_to_memory, select_pc, LEDR8);

    //datapath connections from the state machine
    wire write, asel, bsel, loadc, loads;
    wire [1:0] vsel;
    assign write = out_to_datapath[8];
    assign vsel = out_to_datapath[7:6];
    assign loada = out_to_datapath[5];
    assign loadb = out_to_datapath[4];
    assign asel = out_to_datapath[3];
    assign bsel = out_to_datapath[2];
    assign loadc = out_to_datapath[1];
    assign loads = out_to_datapath[0];

    //memory connections from the state machine
    wire reset_pc, load_pc, load_addr, addr_sel;
    wire [1:0] mem_cmd;
    assign reset_pc = out_to_memory[6];
    assign load_pc = out_to_memory[5];
    assign load_ir = out_to_memory[4];
    assign load_addr = out_to_memory[3];
    assign addr_sel = out_to_memory[2];
    assign mem_cmd = out_to_memory[1:0];

    //PC and Address registers
    wire [15:0] datapath_out; //sximm8_pc
    wire[8:0] next_pc, balls, next_pc_default, next_pc_Rd, PC;
    wire [15:0] data_out;
    assign next_pc_Rd = data_out[7:0];

    //NOTE: since we update the PC before the DECODE state, we end up with a PC one higher than we'd expect when a branch is taken
    //***** This results in a branch jumping to one address higher than we'd like. Thus, we only output PC + sximm8 when pc_select
    //***** is 01
    assign balls = ((select_pc == 2'b10) ? (next_pc_Rd) : ((select_pc == 2'b01) ? PC + sximm8_pc : PC + 1'd1));
    assign next_pc = (reset_pc ? 9'd0 : balls); //pcSelect is the MUX that feeds into the program counter register
   
   //The actual program counter register
    register #(9) programCounter(load_pc, next_pc, clk, PC);

    //The memory address register
    wire [8:0] current_address; //output of the address register
    register #(9) dataAddress(load_addr, datapath_out[8:0], clk, current_address);

    //addrSelect is the MUX that comes from the PC and address registers, and goes towards Memory
    assign mem_addr = (addr_sel ? PC : current_address);

    //instantiation of the datapath
    wire [15:0] mdata;
    assign mdata = read_data;
    
    datapath DP(mdata, sximm8, sximm5, PC[7:0], clk, vsel, asel, bsel, writenum, write, readnumA, readnumB, loada, loadb, loadc, 
                loads, shift, ALUop, Z, N, V, data_out, datapath_out);
   
    //continuously drive the write_data output as the datapath output
    assign write_data = datapath_out;

endmodule