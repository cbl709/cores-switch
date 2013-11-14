//////      input pin     |
//////            |--------------|
//                |              |
//                |              |
//             input_to_A       input_to_B

module input_switch(
                    clk,
                    ctr_io, // ctr_io==0 switch to CPU A else CPU B
                    input_pin,
                    input_to_A,
                    input_to_B
                    );
input clk;
input ctr_io;
input  [7:0] input_pin;
output [7:0] input_to_A;
output [7:0] input_to_B;

reg [7:0] input_to_A;
reg [7:0] input_to_B;

always@(posedge clk)
begin
  if(!ctr_io)
    begin
    input_to_A  <= input_pin;
    input_to_B  <= 8'hzz;
    end
  else begin
    input_to_B  <= input_pin;
    input_to_A  <= 8'hzz;
  end
   
end


endmodule 
