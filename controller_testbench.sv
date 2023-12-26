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


//define memory command variables
`define MNONE 2'b00
`define MREAD 2'b01
`define MWRITE 2'b11


//define ARM registers
`define Rn 3'b001
`define Rd 3'b010
`define Rm 3'b100
`define R_default 3'b001 //Rn 


module controller_tb();

    //signal declerations
    reg reset, clk;
    reg [2:0] opcode; 
    reg [1:0] op;
    wire [2:0] nselA, nselB; //for one-hot select "register select" mux
    wire [8:0] out_to_datapath; //= { write, vsel[1], vsel[0], loada, loadb, asel, bsel, loadc, loads} 
    wire [6:0] out_to_memory; //= {reset_pc, load_pc, load_ir, load_addr, addr_sel, mem_cmd}

    //additional signal declerations
    reg [`SW-1:0] present_state;
    reg err; 

    //instantiation of top-level controller module
    controller DUT(reset, clk, opcode, op, cond, Z, N, V, nselA, nselB, out_to_datapath, out_to_memory, select_pc, LEDR8);

    //task function for repetitive checking 
    task my_task;
        input [`SW-1:0] expected_state; /*
        input [8:0] expected_out_to_datapath;
        input [6:0] expected_out_to_memory;
        input [5:0] expected_nselA;  
        input [2:0] expected_status;
        */
        begin
            if (controller_tb.DUT.present_state !== expected_state) begin
                $display("ERROR:: state is in %b, expected %b.", controller_tb.DUT.present_state, expected_state);
                err = 1'b1;
            end
        end
    endtask

    //first inital block for clock management 
    initial begin               
        clk = 1'b0; #5;
        forever begin 
            clk = 1'b1; #5;
            clk = 1'b0; #5;
        end
    end

    //second initial block to run task function
    initial begin // my_task(expected_state, expected_out_to_datapath, expected_out_to_memory, expected_nsel); 

        //initialize error
        err = 1'b0; 

        //initialize the reset
        reset = 1'b1; opcode = 3'b110; op = 2'b10; #10; 
        my_task(`RST);
        reset = 1'b0;

        //PATH ONE
        $display("Checking PATH ONE...");

        //checking RST to IF1
        $display("Checking RST to IF1...");
        opcode = 3'b110; op = 2'b10; #10;
        my_task(`IF1);

        //checking IF1 to IF2
        $display("Checking IF1 to IF2...");
        opcode = 3'b110; op = 2'b10; #10;
        my_task(`IF2);

        //checking IF2 to UPDATE_PC
        $display("Checking IF2 to UPDATE_PC...");
        opcode = 3'b110; op = 2'b10; #10;
        my_task(`UPDATE_PC);

        //checking UPDATE_PC to DECODE
        $display("Checking UPDATE_PC to DECODE...");
        opcode = 3'b110 ; op = 2'b10; #10;
        my_task(`DECODE);
        
        //checking DECODE to MOV
        $display("Checking DECODE to MOV...");
        opcode = 3'b110 ; op = 2'b10; #10;
        my_task(`MOV);

        //checking MOV to IF1
        $display("Checking MOV to IF1...");
        opcode = 3'b110 ; op = 2'b10; #10;
        my_task(`IF1);


        /*

        //PATH TWO
        $display("Checking PATH TWO...");

        //IF1 to DECODE
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`IF2, 9'b000000000, {5'b00011, `MREAD}, `R_default);
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`UPDATE_PC, 9'b000000000, {5'b01000, `MNONE}, `R_default);
        opcode = 3'b110 ; op = 2'b00; #10;
        my_task(`DECODE, 9'b000000000, {5'b00000, `MNONE}, `R_default);

        //checking DECODE to STR_RM
        $display("Checking DECODE to STR_RM...");
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`STR_RM, 9'b000010000, {5'b00000, `MNONE}, `Rm);

        //checking STR_RM to SHIFT_REG_B
        $display("Checking STR_RM to SHIFT_REG_B...");
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`SHIFT_REG_B, 9'b000001010, {5'b00000, `MNONE}, `R_default);

        //checking SHIFT_REG_B to STR_RD
        $display("Checking SHIFT_REG_B to STR_RD");
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`STR_RD, 9'b111000000, {5'b00000, `MNONE}, `Rd);

        //checking STR_RD to IF1
        $display("Checking STR_RD to IF1");
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`IF1, 9'b000000000, {5'b00001, `MREAD}, `R_default);


        //PATH THREE
        $display("Checking PATH THREE...");

        ///IF1 to DECODE
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`IF2, 9'b000000000, {5'b00011, `MREAD}, `R_default);
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`UPDATE_PC, 9'b000000000, {5'b01000, `MNONE}, `R_default);
        opcode = 3'b110 ; op = 2'b00; #10;
        my_task(`DECODE, 9'b000000000, {5'b00000, `MNONE}, `R_default);

        //checking DECODE to STR_RM
        $display("Checking DECODE to STR_RM...");
        opcode = 3'b101; op = 2'b11; #10;
        my_task(`STR_RM, 9'b000010000, {5'b00000, `MNONE}, `Rm);

        //checking STR_RM to SHIFT_REG_B
        $display("Checking STR_RM to SHIFT_REG_B...");
        opcode = 3'b101; op = 2'b11; #10;
        my_task(`SHIFT_REG_B, 9'b000001010, {5'b00000, `MNONE}, `R_default);

        //checking SHIFT_REG_B to STR_RD
        $display("Checking SHIFT_REG_B to STR_RD");
        opcode = 3'b101; op = 2'b11; #10;
        my_task(`STR_RD, 9'b111000000, {5'b00000, `MNONE}, `Rd);

        //checking STR_RD to IF1
        $display("Checking STR_RD to IF1");
        opcode = 3'b101; op = 2'b11; #10;
        my_task(`IF1, 9'b000000000, {5'b00001, `MREAD}, `R_default);

        
        //PATH FOUR
        $display("Checking PATH FOUR...");    

        //checking IF1 to DECODE
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`IF2, 9'b000000000, {5'b00011, `MREAD}, `R_default);
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`UPDATE_PC, 9'b000000000, {5'b01000, `MNONE}, `R_default);
        opcode = 3'b110 ; op = 2'b00; #10;
        my_task(`DECODE, 9'b000000000, {5'b00000, `MNONE}, `R_default);

        //checking DECODE to STR_RN
        $display("Checking DECODE to STR_RN...");
        opcode = 3'b101; op = 2'b01; #10;
        my_task(`STR_RN, 9'b000100000, {5'b00000, `MNONE}, `Rn);

        //checking STR_RN to STR_RM
        $display("Checking STR_RN to STR_RM...");
        opcode = 3'b101; op = 2'b01; #10;
        my_task(`STR_RM, 9'b000010000, {5'b00000, `MNONE}, `Rm);

        //checking STR_RM to SHIFT_ADD_AND
        $display("Checking STR_RM to SHIFT_ADD_AND...");
        opcode = 3'b101; op = 2'b10; #10;
        my_task(`SHIFT_ADD_AND, 9'b000000010, {5'b00000, `MNONE}, `R_default);

        //checking SHIFT_ADD_AND TO STR_RD
        $display("Checking SHIFT_ADD_AND to STR_RD...");
        opcode = 3'b111; op = 2'b00; #10;
        my_task(`STR_RD, 9'b111000000, {5'b00000, `MNONE}, `Rd);

        //checking STR_RD to IF1
        $display("Checking STR_RD to IF1");
        opcode = 3'b101; op = 2'b11; #10;
        my_task(`IF1, 9'b000000000, {5'b00001, `MREAD}, `R_default);


        //PATH FIVE
        $display("Checking PATH FIVE...");    

        //checking IF1 to DECODE
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`IF2, 9'b000000000, {5'b00011, `MREAD}, `R_default);
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`UPDATE_PC, 9'b000000000, {5'b01000, `MNONE}, `R_default);
        opcode = 3'b110 ; op = 2'b00; #10;
        my_task(`DECODE, 9'b000000000, {5'b00000, `MNONE}, `R_default);

        //checking DECODE to STR_RM
        $display("Checking DECODE to STR_RM...");
        opcode = 3'b101; op = 2'b11; #10;
        my_task(`STR_RM, 9'b000010000, {5'b00000, `MNONE}, `Rm);

        //checking STR_RM to SHIFT_CMP
        $display("Checking STR_RM to SHIFT_CMP...");
        opcode = 3'b101; op = 2'b01; #10;
        my_task(`SHIFT_CMP, 9'b000000001, {5'b00000, `MNONE}, `R_default);

        //checking SHIFT_CMP to IF1
        $display("Checking SHIFT_CMP to IF1...");
        opcode = 3'b111; op = 2'b11; #10;
        my_task(`IF1, 9'b000000000, {5'b00001, `MREAD}, `R_default);


        //PATH SIX
        $display("Checking PATH SIX...");    

        //checking IF1 to DECODE
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`IF2, 9'b000000000, {5'b00011, `MREAD}, `R_default);
        opcode = 3'b110; op = 2'b00; #10;
        my_task(`UPDATE_PC, 9'b000000000, {5'b01000, `MNONE}, `R_default);
        opcode = 3'b110 ; op = 2'b00; #10;
        my_task(`DECODE, 9'b000000000, {5'b00000, `MNONE}, `R_default);

        //checking HALT to HALT
        $display("Checking DECODE to HALT...");
        opcode = 3'b111; op = 2'b00; #10;
        my_task(`HALT, 9'b000000000, {5'b00000, `MNONE}, `R_default);

        //checking HALT to HALT
        $display("Checking HALT to HALT...");
        opcode = 3'b111; op = 2'b00; #10;
        my_task(`HALT, 9'b000000000, {5'b00000, `MNONE}, `R_default);

        //checking HALT to RESET
        $display("Checking HALT to RESET...");
        reset = 1'b1; opcode = 3'b111; op = 2'b00; #10; 
        my_task(`RST, 9'b000000000, {5'b11000, `MNONE}, `R_default);
        reset = 1'b0;


        //PATH SEVEN
        $display("Checking PATH SEVEN...");    

        //checking RST to DECODE
        opcode = 3'b011; op = 2'b00; #10;
        my_task(`IF1, 9'b000000000, {5'b00001, `MREAD}, `R_default);
        opcode = 3'b011; op = 2'b00; #10;
        my_task(`IF2, 9'b000000000, {5'b00011, `MREAD}, `R_default);
        opcode = 3'b011; op = 2'b00; #10;
        my_task(`UPDATE_PC, 9'b000000000, {5'b01000, `MNONE}, `R_default);
        opcode = 3'b011; op = 2'b00; #10;
        my_task(`DECODE, 9'b000000000, {5'b00000, `MNONE}, `R_default);

        //checking DECODE to STR_RN
        $display("Checking DECODE to STR_RN...");
        opcode = 3'b011; op = 2'b00; #10;
        my_task(`STR_RN, 9'b000100000, {5'b00000, `MNONE}, `Rn);

        //checking STR_RN to EFF_ADDR
        $display("Checking STR_RN to EFF_ADDR...");
        opcode = 3'b011; op = 2'b00; #10;
        my_task(`EFF_ADDR, 9'b000000110, {5'b00000, `MNONE}, `R_default);
        
        //checking EFF_ADDR to STR_ADDR
        $display("Checking EFF_ADDR to STR_ADDR...");
        opcode = 3'b011; op = 2'b00; #10;
        my_task(`STR_ADDR, 9'b000000000, {5'b00010, `MNONE}, `R_default);

        //checking STR_ADDR to SEL_ADDR_LDR
        $display("Checking STR_ADDR to SEL_ADDR_LDR...");
        opcode = 3'b011; op = 2'b00; #10;
        my_task(`SEL_ADDR_LDR, 9'b000000000, {5'b00000, `MREAD}, `R_default);

        //checking SEL_ADDR_LDR to STR_MDATA
        $display("Checking SEL_ADDR_LDR to STR_MDATA...");
        opcode = 3'b011; op = 2'b00; #10;
        my_task(`STR_MDATA, 9'b100000000, {5'b00000, `MREAD}, `Rd);

        //checking STR_MDATA to IF1
        $display("Checking STR_MDATA to IF1...");
        opcode = 3'b011; op = 2'b00; #10;
        my_task(`IF1, 9'b000000000, {5'b00001, `MREAD}, `R_default);


        //PATH EIGHT
        $display("Checking PATH EIGHT...");    

        //checking IF1 to DECODE
        opcode = 3'b100; op = 2'b00; #10;
        my_task(`IF2, 9'b000000000, {5'b00011, `MREAD}, `R_default);
        opcode = 3'b100; op = 2'b00; #10;
        my_task(`UPDATE_PC, 9'b000000000, {5'b01000, `MNONE}, `R_default);
        opcode = 3'b100; op = 2'b00; #10;
        my_task(`DECODE, 9'b000000000, {5'b00000, `MNONE}, `R_default);

        //checking DECODE to STR_RN
        $display("Checking DECODE to STR_RN...");
        opcode = 3'b100; op = 2'b00; #10;
        my_task(`STR_RN, 9'b000100000, {5'b00000, `MNONE}, `Rn);

        //checking STR_RN to EFF_ADDR
        $display("Checking STR_RN to EFF_ADDR...");
        opcode = 3'b100; op = 2'b00; #10;
        my_task(`EFF_ADDR, 9'b000000110, {5'b00000, `MNONE}, `R_default);
        
        //checking EFF_ADDR to STR_ADDR
        $display("Checking EFF_ADDR to STR_ADDR...");
        opcode = 3'b100; op = 2'b00; #10;
        my_task(`STR_ADDR, 9'b000000000, {5'b00010, `MNONE}, `R_default);

        //checking STR_ADDR to SEL_ADDR_STR
        $display("Checking STR_ADDR to SEL_ADDR_STR...");
        opcode = 3'b100; op = 2'b00; #10;
        my_task(`SEL_ADDR_STR, 9'b000010000, {5'b00000, `MNONE}, `Rd);

        //checking SEL_ADDR_STR to LOAD_RD
        $display("Checking SEL_ADDR_STR to LOAD_RD...");
        opcode = 3'b100; op = 2'b00; #10;
        my_task(`LOAD_RD, 9'b000001010, {5'b00000, `MNONE}, `R_default);

        //checking LOAD_RD to WRITE _RD
        $display("Checking LOAD_RD to WRITE _RD...");
        opcode = 3'b100; op = 2'b00; #10;
        my_task(`WRITE_RD, 9'b000000000, {5'b00000, `MWRITE}, `R_default);

        //checking WRITE_RD to IF1
        $display("Checking WRITE_RD to IF1...");
        opcode = 3'b100; op = 2'b00; #10;
        my_task(`IF1, 9'b000000000, {5'b00001, `MREAD}, `R_default);

        */

        //results
        if(~err) 
            $display("PASSED");
        else
            $display("FAILED");

        //stop the simulation
        $stop;
    end

endmodule