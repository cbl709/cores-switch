//////      output pin   |
//////            |--------------|
//                |              |
//                |              |
//             output_from_A   output_from_B

module output_switch(
                    clk,
                    ctr_io, // ctr_io==0 switch to CPU A else CPU B
                    output_pin,
                    output_from_A,
                    output_from_B
                    );
input clk;
input ctr_io;
output  [7:0] output_pin;
input   [7:0] output_from_A;
reg     [7:0] A_reg;
input   [7:0] output_from_B;
reg     [7:0] B_reg;

//reg [7:0] output_pin=8'hff;

assign output_pin= ~ctr_io? output_from_A: output_from_B;
/*always@ (posedge clk)
begin
  A_reg <=output_from_A;
  B_reg <=output_from_B;
  if(!ctr_io)
    output_pin  <= A_reg;
  else 
    output_pin  <= B_reg;
    
   
end*/


endmodule 
