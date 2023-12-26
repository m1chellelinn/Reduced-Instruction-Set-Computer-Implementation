module shifter(in, shift, sout);

        input [15:0] in;
        input [1:0] shift;
        output reg [15:0] sout; 

        //Chooses the operation to perform based on the "shift" signal
        always_comb begin 
            
            sout = in;

            case(shift)

            2'b01: sout = in << 1;

            2'b10: sout = in >> 1; 

            2'b11: begin 
                   sout = in >> 1;
                   sout[15] = in[15];
            end

            default: sout = in; 

            endcase
            
        end

endmodule