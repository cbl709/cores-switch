module async_dly(
                 clk,
                 in,
                 out
                );
input clk;
input in;
output out;

reg [63:0] data=64'hffffffffffffffff;

always@(posedge clk)
begin

 data[63:0] <= {data[62:0],in};

end

assign out=data[63];
















endmodule
