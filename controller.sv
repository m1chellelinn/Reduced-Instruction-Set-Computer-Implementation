//state-width - change as we add more states
`define SW 3'b101  

//define states
`define RST 5'd0 //waiting for signal 's' to begin
`define IF1 5'd1 //selects the current address from the PC and requests to read memory 
`define IF2 5'd2 //loads the instruction read from memory into the instruction register 
`define UPDATE_PC 5'd3 //loads the PC register with the "new" address (incremented value) 
`define DECODE 5'd4 //decides which type of instruction is being run
`define BRANCH_TAKEN 5'd5 //sets select_pc to 1 to move sximm8 into the reset_pc mulitplexer - loads the program counter register so IF1 is ready
`define LR_WRITE 5'd6 //saves address of next instruction to the link register, R7
`define BX_START 5'd7 //start of the BX instruction: calls datapath to move value at Rd to data_out
`define PC_WRITE 5'd8 //moves the value at data_out into the program counter - loads the program counter register so IF1 is ready
`define HALT 5'd9 //halts the program
`define MOV 5'd10 //moves an immediate value sximm8 into Rd
`define EXECUTE 5'd11 //reads Rn and Rm from the regfile, shifts Rm and loads to result into register C
`define STR_RD 5'd12 //writes the value stored in Register C to memory in Rd
`define STATUS_CMP 5'd13 //stores the result of an CMP instruction into the status register
`define EFF_ADDR 5'd14 //calculates the effective address of a LDR or STR instruction
`define STR_ADDR 5'd15 //loads the effective address into the address register 
`define SEL_ADDR_LDR 5'd16 //sets the address select mux to select the address from the address register - requests to read
`define STR_MDATA 5'd17 //sends the value found at effective address to writeback mux - writes to Rd after returning to IF1  
`define SEL_ADDR_STR 5'd18 //sends the effective address to memory - loads the value of Rd into the pipeline register B
`define WRITE_RD 5'd19 //writes value of Rd to effective address
`define LOAD_AB 5'd20 
`define MOV_RM 5'd21
`define LOAD_RD 5'd22


//define memory command variables
`define MNONE 2'b00
`define MREAD 2'b01
`define MWRITE 2'b11


//define ARM registers
`define Rn 3'b001
`define Rd 3'b010
`define Rm 3'b100
`define R_default 3'b001 //Rn 

//start of controller module
module controller(reset, clk, opcode, op, cond, Z, N, V, nselA, nselB, out_to_datapath, out_to_memory, select_pc, LEDR8);

    input reset, clk;
    input [2:0] opcode, cond; 
    input [1:0] op;
    input Z,N,V;
    output reg [2:0] nselA, nselB; //for one-hot select "register select" mux - nselA for data_outA and writenum, nselB for data_outB
    output reg [8:0] out_to_datapath; //= {write, vsel[1], vsel[0], loada, loadb, asel, bsel, loadc, load}
    output reg [6:0] out_to_memory; //= {reset_pc, load_pc, load_ir, load_addr, addr_sel, mem_cmd}
    output reg [1:0] select_pc;
    output reg LEDR8;

    //additional signal declerations
    reg [`SW-1:0] present_state; 

    //main always block to update the present state and the controller output to the datapath
    always_ff @(posedge clk) begin 

        //if reset is HIGH, return to the WAIT state
        if(reset) begin         
            present_state = `RST;
            out_to_datapath = 9'b00000000; 
            out_to_memory = {5'b11000, `MNONE};
            {nselA,nselB} = {`R_default,`R_default};
            select_pc = 2'b00;
            LEDR8 = 1'b0;
        end

        //otherwise, check inputs and update the present state
        else begin  
            //case statement to update present_state
            case(present_state)   
                `RST:  present_state = `IF1; //proceed to IF1 state

                `IF1: present_state = `IF2; //proceed to IF2 state

                `IF2: present_state = `UPDATE_PC; //proceed to UPDATE_PC state

                `UPDATE_PC: present_state = `DECODE; //proceed to DECODE 

                `DECODE:begin
                        case(opcode)
                                3'b110: begin
                                        if(op == 2'b10)
                                                present_state = `MOV;
                                        else if(op == 2'b00)
                                                present_state = `LOAD_AB;
                                end
                                3'b101: present_state = `LOAD_AB;
                                
                                3'b111: present_state = `HALT;

                                3'b011, 3'b100: present_state = `LOAD_AB;
                                3'b001: begin
                                        if((cond == 3'b000) || (cond == 3'b001 && Z == 1'b1) || (cond == 3'b010 && Z == 1'b0) || (cond == 3'b011 && N!== V) || (cond == 3'b100 && (N !== V || Z == 1'b1)))
                                                present_state = `BRANCH_TAKEN;
                                        else if((cond == 3'b001 && Z !== 1'b1) || (cond == 3'b010 && Z !== 1'b0) || (cond == 3'b011 && N == V) || (cond == 3'b100 && (N == V || Z !== 1'b1)))
                                                present_state = `IF1;
                                end
                                3'b010: begin
                                        if(op == 2'b11 || op == 2'b10)
                                                present_state = `LR_WRITE;
                                        else if(op == 2'b00)
                                                present_state = `BX_START;
                                end
                                default: present_state = `HALT; //if no valid input, go to HALT
                        endcase
                end

                /*
                if(opcode == 3'b110 && op == 2'b10) //if we are performing a MOV instruction, go to the MOV state
                                present_state = `MOV;
                        else if(opcode == 3'b110 && op == 2'b00) //if we are performing a MOV instruction with a register
                                present_state = `MOV_RM; 
                        else if(opcode == 3'b101 && op == 2'b01) //if we are performing a CMP instruction, go to the STATUS_CMP state
                                present_state = `STATUS_CMP;
                        else if(opcode == 3'b111) //if the program is finished executing, move to the HALT state
                                present_state = `HALT;
                        else if(opcode == 3'b011 || opcode == 3'b100)
                                present_state = `EFF_ADDR;
                        else if(opcode == 3'b001 && (
                                (cond == 3'b000) || 
                                (cond == 3'b001 && Z == 1'b1) || 
                                (cond == 3'b010 && Z == 1'b0) || 
                                (cond == 3'b011 && N!== V) || 
                                (cond == 3'b100 && (N !== V || Z == 1'b1)))
                                ) //if a branch is taken, move to the BRANCH_TAKEN state
                                
                                present_state = `BRANCH_TAKEN;
                        else if(opcode == 3'b001 && ((cond == 3'b001 && Z !== 1'b1) || (cond == 3'b010 && Z !== 1'b0) || (cond == 3'b011 && N == V) || (cond == 3'b100 && (N == V || Z !== 1'b1)))) //if a branch is taken, move to the BRANCH_TAKEN state)
                                present_state = `IF1;
                        else if(opcode == 3'b010 && (op == 2'b11 || op == 2'b10)) //if need to store the next instruction's address, we move to the LR_WRITE state
                                present_state = `LR_WRITE;
                        else if(opcode == 3'b010 && op == 2'b00) //if performing a BX instruction (PC = Rd), move to the BX_START state
                                present_state = `BX_START;
                        else if(opcode == 3'b101 && op !== 2'b01)
                                present_state = `EXECUTE; //otherwise, we must be performing ADD,AND,MVM instruction
                        else
                                present_state = `HALT; //if no valid input, go to HALT
                */

                /*
                else if((opcode == 3'b110 && op == 2'b00) || (opcode == 3'b101 && op == 2'b11)) //if we are performing a MVM or MOV, {,<sh_op} instruction, go to STR_RM state
                            present_state = `STR_RM;
                else if((opcode == 3'b101) || (opcode == 3'b011) || (opcode == 3'b100)) //otherwise, we are performing an ADD, AND, CMP, LDR or STR and should go to the STR_RN state
                            present_state = `STR_RN;
                */

                `BRANCH_TAKEN: present_state = `IF1;

                `HALT: present_state = `HALT;

                `LR_WRITE: begin
                        if (op == 2'b11) 
                                present_state = `BRANCH_TAKEN;
                        else if (op == 2'b10) 
                                present_state = `BX_START;
                        else 
                                present_state = `HALT;
                end

                `BX_START: present_state = `PC_WRITE;
                
                `PC_WRITE: present_state = `IF1;

                `MOV: present_state = `IF1; //once finished storing an immediate in Rd, return to the WAIT state

                `LOAD_AB: if(opcode == 3'b101 && op == 2'b01)
                                present_state = `STATUS_CMP;
                        else if(opcode == 3'b110)
                                present_state = `MOV_RM;
                        else if(opcode == 3'b011 || opcode == 3'b100) 
                                present_state = `EFF_ADDR;
                        else   
                                present_state = `EXECUTE;

                `EFF_ADDR: present_state = `STR_ADDR;

                `MOV_RM: present_state = `STR_RD;

                `EXECUTE: present_state = `STR_RD;

                `STR_ADDR:begin
                        if(opcode == 3'b011)
                            present_state = `SEL_ADDR_LDR; //if opcode is 011, we are performing a LDR instruction
                        else    
                            present_state = `SEL_ADDR_STR; //otherwise we are performing a STR instruction
                end

                `SEL_ADDR_STR: present_state = `LOAD_RD;

                `LOAD_RD: present_state = `WRITE_RD;

                `WRITE_RD: present_state = `IF1; //once we've written the value of Rd into the effective address, return to the IF1 state for next instruction 

                `SEL_ADDR_LDR: present_state = `STR_MDATA;

                `STR_MDATA: present_state = `IF1; //once we've stored the read data into Rd, return to the IF1 state for next instruction

                `EXECUTE: present_state = `STR_RD;

                `STATUS_CMP: present_state = `IF1;

                `STR_RD: present_state = `IF1; //once done writing the result to Rd, fetch the next instruction
            
                default: present_state = `IF1; 
            endcase
        
        //case statement to update the outputs of the controller (the inputs to the datapath and the inputs to memory/PC) 
        case(present_state)  //out_to_datapath = { write, vsel[1], vsel[0], loada, loadb, asel, bsel, loadc, loads} 
                             //out_to_memory= {reset_pc, load_pc, load_ir, load_addr, addr_sel, mem_cmd}

                `IF1: begin
                        out_to_datapath = 9'b000000000;
                        out_to_memory = {5'b00001, `MREAD};
                        {nselA, nselB} = {`R_default,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0; 
                end

                `IF2: begin
                        out_to_datapath = 9'b000000000;
                        out_to_memory = {5'b00111, `MREAD};
                        {nselA, nselB} = {`R_default,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end

                `UPDATE_PC:begin
                        out_to_datapath = 9'b000000000;
                        out_to_memory = {5'b01000, `MNONE}; 
                        {nselA, nselB} = {`R_default,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end

                `DECODE:begin
                        out_to_datapath = 9'b000000000;
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA, nselB} = {`R_default,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end

                `BRANCH_TAKEN: begin
                        out_to_datapath = 9'b000000000;
                        out_to_memory = {5'b01000, `MNONE};
                        {nselA, nselB} = {`R_default,`R_default};
                        select_pc = 2'b01;
                        LEDR8 = 1'b0;
                end
                //out_to_datapath = { write, vsel[1], vsel[0], loada, loadb, asel, bsel, loadc, loads}
                `LR_WRITE:begin
                        out_to_datapath = 9'b110000000;
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA,nselB} = {`Rn,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end

                `BX_START:begin
                        out_to_datapath = 9'b000000000;
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA,nselB} = {`Rd,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end

                `PC_WRITE:begin
                        out_to_datapath = 9'b000000000;
                        out_to_memory = {5'b01000, `MNONE};
                        {nselA,nselB} = {`Rd,`R_default};
                        select_pc = 2'b10;
                        LEDR8 = 1'b0;
                end

                `HALT:   begin    
                        out_to_datapath = 9'b000000000;
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA, nselB} = {`R_default,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b1;
                end
                
                `MOV:   begin
                        out_to_datapath = 9'b101000000; //write = 1, vsel = 01, nsel = Rn
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA,nselB} = {`Rn,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end
                //out_to_datapath = { write, vsel[1], vsel[0], loada, loadb, asel, bsel, loadc, loads}
                `MOV_RM: begin
                        out_to_datapath = 9'b000001010; 
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA,nselB} = {`R_default,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end
                
                `LOAD_AB: begin
                        out_to_datapath = 9'b000110000; 
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA,nselB} = {`Rn,`Rm};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end

                //computes an ADD,AND,MVN operation and stores result in register C
                `EXECUTE: begin
                        out_to_datapath = 9'b000000010; 
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA,nselB} = {`Rn,`Rm};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end
                
                //calculates effective address and stores it into register C
                `EFF_ADDR: begin
                        out_to_datapath = 9'b000000110;
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA, nselB} = {`Rn,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end

                //loads the effective address into the address register
                `STR_ADDR: begin
                        out_to_datapath = 9'b000000000;
                        out_to_memory = {5'b00010, `MNONE};
                        {nselA, nselB} = {`R_default,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end

                //sends effective address to memory and requests to read
                `SEL_ADDR_LDR:begin
                        out_to_datapath = 9'b000000000;
                        out_to_memory = {5'b00000, `MREAD};
                        {nselA, nselB} = {`R_default,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end

                //sends data stored at effective address through mdata - stored into Rd upon leaving STR_MDATA state
                `STR_MDATA: begin
                        out_to_datapath = 9'b100000000;
                        out_to_memory = {5'b00000, `MREAD};
                        {nselA,nselB} = {`Rd,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end
                //out_to_datapath = { write, vsel[1], vsel[0], loada, loadb, asel, bsel, loadc, loads}
                //sends effective address to memory - stores Rd into register B
                `SEL_ADDR_STR: begin
                        out_to_datapath = 9'b000010000;
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA,nselB} = {`R_default,`Rd};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end

                `LOAD_RD: begin
                        out_to_datapath = 9'b000001010;
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA,nselB} = {`R_default,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0; 
                end
                
                //additional state to write the "din" input into memory at effective address 
                `WRITE_RD: begin
                        out_to_datapath = 9'b000000000;
                        out_to_memory = {5'b00000, `MWRITE};
                        {nselA, nselB} = {`R_default,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end
                 
                //calculate Rn-Rm, update the status register with the result
                `STATUS_CMP: begin
                        out_to_datapath = 9'b000000001; //asel = 0, bsel = 0, loadc = 0, loads = 1
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA, nselB} = {3'b001,3'b100};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end
                //{ write, vsel[1], vsel[0], asel, bsel, loadc, loads}
                //write the value in Register C to Rd
                `STR_RD: begin
                        out_to_datapath = 9'b111000000; 
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA,nselB} = {`Rd,`R_default}; 
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end

                default:begin 
                        out_to_datapath = 9'b000000000;
                        out_to_memory = {5'b00000, `MNONE};
                        {nselA, nselB} = {`R_default,`R_default};
                        select_pc = 2'b00;
                        LEDR8 = 1'b0;
                end

            endcase
        end
    end

endmodule