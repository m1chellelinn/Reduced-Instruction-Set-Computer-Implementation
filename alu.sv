//some modification have been made so that the correct flags are output from the ALU
module ALU(Ain, Bin, ALUop, out, Z, N, V);

    input [15:0] Ain, Bin;
    input [1:0] ALUop;
    output reg [15:0] out;
    output reg Z, N, V; //status flags to indicate a zero or negative output or overflow

    //Computes the output given the operation to perform
    always_comb begin
    
        //reg variable to store temporary result of addition - used to detect overflow
        reg [16:0] temp_result;

        case(ALUop)

        2'b00: begin
                temp_result = {Ain[15], Ain} + {Bin[15], Bin}; 
                out = temp_result [15:0]; //out is assigned the actual addition of Ain and Bin
                V = temp_result [16] ^ temp_result [15]; //XOR gate to detect overflow if signs are different 
        end

        2'b01: begin
                temp_result = {Ain[15], Ain} - {Bin[15], Bin};
                out = temp_result[15:0];
                V = (Ain[15] ^ Bin[15]) & (Ain[15] ^ out[15]);
        end
        
        2'b10: begin
               out = Ain & Bin;
               V = 1'b0;
        end

        2'b11: begin
               out = ~Bin;
               V = 1'b0;
        end

        default: begin
                  out = Ain;
                  V = 1'b0;
        end

        endcase
    end
    
    //Combinational logic to calculate the status flags Z and N
    always_comb begin
        
        //if output is zero, set the Z flag to 1
        if(out == 16'd0)
            Z = 1'b1;
        else 
            Z = 1'b0; 

        //if output is negative, set the N flag to 1
        N = out[15];
   
    end
    
endmodule