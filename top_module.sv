//define memory command variables
`define MNONE 2'b00
`define MREAD 2'b01
`define MWRITE 2'b11

//(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,CLOCK_50);
module lab7bonus_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,CLOCK_50);

    //I/O declerations (included)
    input CLOCK_50;
    input [3:0] KEY;
    input [9:0] SW;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    //************************************
    //Button map guide
    //
    //clk   ---- CLOCK_50
    //reset ---- ~KEY[1]
    //
    //************************************

    //initialize the reverse logic of the pushbuttons
    wire clk, reset;
    assign clk = CLOCK_50;
    assign reset = ~KEY[1];

    //HEX displays are disconnected
    assign HEX0 = 7'b1111111;
    assign HEX1 = 7'b1111111;
    assign HEX2 = 7'b1111111;
    assign HEX3 = 7'b1111111;
    assign HEX4 = 7'b1111111;
    assign HEX5 = 7'b1111111;
    //LEDR [9] is not used - LEDR [8] should be high only in the HALT state 
    assign LEDR[9] = 1'b0;
    wire LEDR8;
    assign LEDR[8] = LEDR8;

    //************************************
    //Module instantiation guide
    //
    //module RAM(clk,read_address,write_address,write,din,dout);
    //module cpu(clk, reset, read_data, N, V, Z, write_data, mem_addr, mem_cmd); 
    //
    //************************************

    //CPU
    //output signals from the CPU
    wire [15:0] read_data, write_data; 
    wire N, V, Z; //disconnected
    wire [8:0] mem_addr;
    wire [1:0] mem_cmd;
    //instantiation of the CPU
    cpu CPU(clk, reset, read_data, write_data, mem_addr, mem_cmd, LEDR8);
    //module cpu(clk, reset, read_data, write_data, mem_addr, mem_cmd);

    //MEMORY
    //write signal
    wire write;
    assign write = (((mem_cmd == `MWRITE) ? 1'b1 : 1'b0) & ((mem_addr[8] == 1'b0) ? 1'b1 : 1'b0));  

    //tri-state driver for read requests
    wire msel; 
    assign msel = ((mem_addr[8] == 1'b0) ? 1'b1 : 1'b0);
    wire enable; 
    assign enable = ((msel) & ((mem_cmd == `MREAD) ? 1'b1 : 1'b0));
    wire [15:0] dout; 
    assign read_data = (enable ? dout : {16{1'bz}});

    //data in
    wire [15:0] din;
    assign din = write_data;

    //address input to RAM
    wire [8:0] read_address, write_address;
    assign read_address = mem_addr[7:0]; 
    assign write_address = mem_addr[7:0];

    //instantiate RAM
    RAM #(16, 8, "data.txt") MEM(clk, read_address[7:0], write_address[7:0], write, din, dout);
    

    //I/O INTERFACE
    wire [1:0] mem_cmd_output;
    wire [8:0] mem_addr_output; 
    wire [15:0] write_data_output; 
    interfaceIO IO(clk, SW[7:0], LEDR[7:0], mem_cmd, mem_addr, read_data, write_data, mem_cmd_output, mem_addr_output, write_data_output);


endmodule


// To ensure Quartus uses the embedded MLAB memory blocks inside the Cyclone
// V on your DE1-SoC we follow the coding style from in Altera's Quartus II
// Handbook (QII5V1 2015.05.04) in Chapter 12, “Recommended HDL Coding Style”

module RAM(clk,read_address,write_address,write,din,dout);

    parameter data_width = 32;
    parameter addr_width = 4;
    parameter filename = "data.txt";
    input clk;
    input [addr_width-1:0] read_address, write_address;
    input write;
    input [data_width-1:0] din;
    output [data_width-1:0] dout;

    reg [data_width-1:0] dout;
    reg [data_width-1:0] mem [2**addr_width-1:0];

    initial $readmemb(filename, mem);

        always @ (posedge clk) begin
            if (write)
                mem[write_address] <= din;
                dout <= mem[read_address]; // dout doesn't get din in this clock cycle (this is due to Verilog non-blocking assignment "<=")
        end 
        
endmodule


//logic for I/O interface
module interfaceIO(clk, SW, LEDR, mem_cmd, mem_addr, read_data, write_data, mem_cmd_output, mem_addr_output, write_data_output);

    input clk;
    input [7:0] SW;
    input [1:0] mem_cmd;
    input [8:0] mem_addr;
    input [15:0] write_data;
    output [15:0] read_data;
    output [1:0] mem_cmd_output;
    output [8:0] mem_addr_output; 
    output [15:0] write_data_output; 
    output [7:0] LEDR; 

    //signals mem_cmd_output, mem_addr_output, write_data_output should be continously assigned their input values
    assign mem_cmd_output = mem_cmd;
    assign mem_addr_output = mem_addr;
    assign write_data_output = write_data;
    //no idea what these outputs are actually for. Just following the skematic on this one


    //SLIDER SWITCH LOGIC (INPUT)
    //For the slider switches you want to enable the tri-state drive when the memory command (mem_cmd) is a read
    //operation and the address on mem_addr is 0x140.
    
    wire enable;
    assign enable = (((mem_cmd == `MREAD) && (mem_addr == 9'h140)) ? 1'b1 : 1'b0);

    //two tri-state drivers
    assign read_data[15:8] = (enable ? 8'h00 : {8{1'bz}});
    assign read_data[7:0] = (enable ? SW : {8{1'bz}});


    //LEDR LOGIC (OUTPUT)
    //For the red LEDs you want to load the register when the memory command indicates a write operation and the
    //address on mem_addr is 0x100.

    wire load; 
    assign load = (((mem_cmd == `MWRITE) && (mem_addr == 9'h100)) ? 1'b1 : 1'b0);

    //register
    register #(8) LEDR_REG(load, write_data[7:0], clk, LEDR);
     
endmodule 