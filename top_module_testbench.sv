module lab7top_bonus_tb;
  reg [3:0] KEY;
  reg [9:0] SW;
  wire [9:0] LEDR; 
  wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
  reg err;
  reg CLOCK_50;

  lab7bonus_top DUT(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,CLOCK_50);

  initial forever begin
    CLOCK_50 = 0; #5;
    CLOCK_50 = 1; #5;
  end

  initial begin
    err = 0;
    KEY[1] = 1'b0; // reset asserted
    #10;
    KEY[1] = 1'b1; //reset deasserted 

    @(posedge LEDR[8]); #20; // set LEDR[8] to one when executing HALT
    if(DUT.CPU.DP.REGFILE.R1 !== 16'd50); err = 1'b1;

    if (~err) 
        $display("INTERFACE OK");
    else 
        $display("ERROR: R0 is %b, but was expecting %b.", DUT.CPU.DP.REGFILE.R0, 16'd50);
    $stop;
    end

endmodule 