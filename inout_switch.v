
module inout_switch(
                    clk,
                    out_en, //
                    ctr_io, 
                    inout_pin,
                    inout_A,
                    inout_B
                    );
input clk;
input out_en;
input ctr_io;
inout [7:0] inout_pin;
inout [7:0] inout_A;
inout [7:0] inout_B;

reg [7:0] input_pin;
reg  [7:0] output_pin;

reg [7:0] input_to_A;
reg  [7:0] output_from_A;

reg [7:0] input_to_B;
reg  [7:0] output_from_B;


//assign input_pin= inout_pin;
assign inout_pin=~out_en?output_pin:8'hzz;

//assign input_to_A= inout_A;
assign inout_A=out_en?output_from_A:8'hzz;

//assign input_to_B= inout_B;
assign inout_B=out_en?output_from_B:8'hzz;

always@(posedge clk)
begin
 output_from_A <= inout_A;
 output_from_B <= inout_B;
  if(~ctr_io) begin
    output_pin <= output_from_A;
    input_to_A <= input_pin;
    input_to_B <= 8'hff;
    end
  else begin
    output_pin<= output_from_B;
    input_to_B <= input_pin;
    input_to_A <= 8'hff;
    end
end




endmodule 
