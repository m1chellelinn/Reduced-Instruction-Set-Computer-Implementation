module cpu_tb ();
    reg clk, reset, s, load;
    reg [15:0] in; 
    reg N, V, Z, w;
    wire [15:0] out;

    reg err;

    cpu DUT(clk,reset,s,load,in,out,N,V,Z,w);

    // input clk, reset, s, load;
    // input [15:0] in;
    // output [15:0] out;
    // output N, V, Z, w;

    task test;
        input [15:0] expected_out;
        input expected_N;
        input expected_V;
        input expected_Z;
        input expected_w;

        begin
            if ( out !== expected_out) begin
                    $display("ERROR:: output is %b, expected %b.", out, expected_out);
                    err = 1'b1;
            end
            if ( N !== expected_N) begin
                    $display("ERROR:: N flag is %b, expected %b.", N, expected_N);
                    err = 1'b1;
            end
            if ( V !== expected_V) begin
                    $display("ERROR:: V flag is %b, expected %b.", V, expected_V);
                    err = 1'b1;
            end
            if ( Z !== expected_Z) begin
                    $display("ERROR:: Z flag is %b, expected %b.", Z, expected_Z);
                    err = 1'b1;
            end

            if ( w !== expected_w) begin
                    $display("ERROR:: 'wait' is %b, expected %b.", w, expected_w);
                    err = 1'b1;
            end
        end
    endtask

    //start of first initial block for clk management 
    initial begin               
        clk = 1'b0; #5;
        forever begin 
            clk = 1'b1; #5;
            clk = 1'b0; #5;
        end
    end

    //start of second initial block for running checks
    initial begin
        
        //initialize error and reset
        err = 1'b0; 
        reset = 1'b1; #10; reset = 1'b0;


        //CHECK ONE
        //Running check: R5=1, R6=2, R6>>1; ALU: 1-1, expects Z=1, N=0, V=0 and out=0
        //MOV R5, #1 -> 110 10 101 00000001
        //MOV R6, #2 -> 110 10 110 00000010
        //ADD R0, R6, R5 -> 101 00 101 000 00 110
        //CMP R5, R6, RSL #1 -> 101 01 101 000 10 110

        //MOV R5, #1
        $display("MOV R5, #1");
        load = 1'b1; in = 16'b1101010100000001; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;

        //MOV R6, #2
        $display("MOV R6, #2");
        load = 1'b1; in = 16'b1101011000000010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;

        //ADD R0, R6, R5
        $display("ADD R0, R6, R5");
        load = 1'b1; in = 16'b1010010100000110; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;

        //CMP R5, R6, LSR #1
        $display("CMP R5, R6, RSL #1");
        load = 1'b1; in = 16'b1010110100010110; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;
        test(16'd3, 1'b0, 1'b0, 1'b1, 1'b1);


        //CHECK TWO
        //Running check: R0=7, R1=2, R0<<1, ALU:2+14, expects Z=1, N=0, V=0 and out=16.
        //MOV R0, #7 - > 1101000000000111
        //MOV R1, #2 - > 1101000100000010
        //ADD R2, R1, R0, LSL #1  - > 1010000101001000

        //MOV R0, #7
        $display("MOV, R0, #7");
        load = 1'b1; in = 16'b1101000000000111; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70; 

        //MOV R1, #2
        $display("MOV, R1, #2");
        load = 1'b1; in = 16'b1101000100000010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;
        
        //ADD R2, R1, R0, LSL #1
        $display("ADD R2, R1, R0, LSL #1");
        load = 1'b1; in = 16'b1010000101001000; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;
        test(16'd16, 1'b0, 1'b0, 1'b1, 1'b1);

        //CHECK SIX -- tests load and start reliability
        //CMP R2, R6 -> do not assert load -> check that output is still d16
        //      101 01 010 000 00 110
        //AND R3, R2, R6 -> assert load but do not start -> check that output is still d16
        //      101 10 010 011 00 110
        //ADD R3, R2, r6 -> assert load but do not start -> check that output is still d16
        //      101 00 010 011 00 110
        //Finally, assert start. Check that output is 16+15=31

        $display ("CMP R2, R6, do not load/start");
        load = 1'b0; in = 16'b1010101000000110; #70;
        test(16'd16, 1'b0, 1'b0, 1'b1, 1'b1);

        $display ("AND R3, R2, R6, load but do not start");
        load = 1'b1; in = 16'b1011001001100110; #10; load = 1'b0; #70;
        test(16'd16, 1'b0, 1'b0, 1'b1, 1'b1);

        $display ("ADD R3, R2, r6, load but do not start");
        load = 1'b1; in = 16'b1010001001100110; #10; load = 1'b0; #70;
        test(16'd16, 1'b0, 1'b0, 1'b1, 1'b1);

        $display ("Start add instruction");
        s = 1'b1; #10; s = 1'b0; #70;
        test(16'd18, 1'b0, 1'b0, 1'b1, 1'b1);

        //CHECK SEVEN -- check repeating one instruction & a big number
        //MOV R5, #127 -> 110 10 101 01111111
        //repeat 8 times:
        //MOV R2, R5 -> 110 00 000 010 00 101
        //ADD R5, R5, R2 -> 101 00 101 101 00 010
        //output sequence: 510, 1020, 2040, 4080, 8160, 16320, 32640, 65280

        $display("MOV R5, #127");
        load = 1'b1; in = 16'b1101010101111111; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;

        $display("Starts 8 loops of (MOV R2, R5) then (ADD R5, R5, R2):");
        load = 1'b1; in = 16'b1100000001000101; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #70;
        load = 1'b1; in = 16'b1010010110100010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #70;
        test(16'd254, 1'b0, 1'b0, 1'b1, 1'b1);

        load = 1'b1; in = 16'b1100000001000101; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #70;
        load = 1'b1; in = 16'b1010010110100010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #50;
        test(16'd508, 1'b0, 1'b0, 1'b1, 1'b1);

        load = 1'b1; in = 16'b1100000001000101; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #40;
        load = 1'b1; in = 16'b1010010110100010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #50;
        test(16'd1016, 1'b0, 1'b0, 1'b1, 1'b1);

        load = 1'b1; in = 16'b1100000001000101; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #40;
        load = 1'b1; in = 16'b1010010110100010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #50;
        test(16'd2032, 1'b0, 1'b0, 1'b1, 1'b1);

        load = 1'b1; in = 16'b1100000001000101; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #40;
        load = 1'b1; in = 16'b1010010110100010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #50;
        test(16'd4064, 1'b0, 1'b0, 1'b1, 1'b1);

        load = 1'b1; in = 16'b1100000001000101; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #40;
        load = 1'b1; in = 16'b1010010110100010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #50;
        test(16'd8128, 1'b0, 1'b0, 1'b1, 1'b1);

        load = 1'b1; in = 16'b1100000001000101; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #40;
        load = 1'b1; in = 16'b1010010110100010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #50;
        test(16'd16256, 1'b0, 1'b0, 1'b1, 1'b1);

        load = 1'b1; in = 16'b1100000001000101; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #40;
        load = 1'b1; in = 16'b1010010110100010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #50;
        test(16'd32512, 1'b0, 1'b0, 1'b1, 1'b1);

        load = 1'b1; in = 16'b1100000001000101; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #40;
        load = 1'b1; in = 16'b1010010110100010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0; #50;
        test(16'd65024, 1'b0, 1'b0, 1'b1, 1'b1);

        in = 16'd16; N = 1'b0; V = 1'b0; Z = 1'b1;


        //CHECK THREE
        //Running check: R7= 01111, ALU:bitwise NOT R7, expects Z=1, N=0, V=0 and out=1111 1111 1111 0000
        //MOV R7, #15 -> 110 10 111 00001111
        //MOV R6, R7 -> 110 00 000 110 00 111
        //MVN R0, R7 -> 101 11 000 000 00 111

        //MOV R7, #15
        $display("MOV R7, #15");
        load = 1'b1; in = 16'b1101011100001111; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70; 

        //MOV R6, R7
        $display("MOV R6, R7");
        load = 1'b1; in = 16'b1100000011000111; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;
        
        //MVN R0, R7
        $display("MVN R0, R7");
        load = 1'b1; in = 16'b1011100000000111; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;
        test(16'b1111111111110000, 1'b0, 1'b0, 1'b1, 1'b1);


        //CHECK FOUR
        //Running check R1 = -127, R2 = -64, ADD R0, R1, R2, LSR #1 expects Z=0, N=1, V=0, out = 
        //MOV R1, #-127 -> 110 10 001 10000001
        //MOV R2, R1, LSR #1 -> 110 00 000 010 11 001
        //CMP R1, R2, LSR #1 -> 101 01 001 000 11 010
        //ADD R0, R2, R1, LSL #1 -> 101 00 010 000 01 001
        
        //MOV R1, #-127
        $display("MOV R1, #-127");
        load = 1'b1; in = 16'b1101000110000001; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70; 

        //MOV R2, R1, LSR #1
        $display("MOV R2, R1, LSR #1");
        load = 1'b1; in = 16'b1100000001011001; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;
        
        //CMP R1, R2, LSR #1
        $display("CMP R1, R2, LSR #1");
        load = 1'b1; in = 16'b1010100100011010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;

        //ADD R0, R2, R1, LSL #1
        $display("ADD R0, R2, R1, LSL #1");
        load = 1'b1; in = 16'b1010001000001001; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;
        test(16'sb1111111011000010, 1'b1, 1'b0, 1'b0, 1'b1);
    

        //CHECK FIVE
        //Running check R4 = 69, R5 = 2, AND R3, R4, R5, LSL #1  LSL #1 expects Z=0, N=1, V=0, out = 16'b0000000000000100
        //MOV R4, #69 -> 110 10 100 01000101
        //MOV R5, #2 -> 110 10 101 00000010
        //AND R3, R4, R5, LSL #1 -> 101 10 100 011 01 101
        
        //MOV R4, #69
        $display("MOV R4, #69");
        load = 1'b1; in = 16'b1101010001000101; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70; 

        //MOV R6, R7
        $display("MOV R6, R7");
        load = 1'b1; in = 16'b1101010100000010; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;
        
        //MVN R0, R7
        $display("MVN R0, R7");
        load = 1'b1; in = 16'b1011010001101101; #10; s = 1'b1; #10; load = 1'b0; s = 1'b0;
        #70;
        test(16'b0000000000000100, 1'b1, 1'b0, 1'b0, 1'b1);

        //results
        if(~err) 
            $display("PASSED");
        else
            $display("FAILED");

        $stop;
    end

endmodule