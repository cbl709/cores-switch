`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:47:55 12/13/2012 
// Design Name: 
// Module Name:    pulse_gen 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module pulse_gen( clk,
						rst_n,
						pulse
					 );
input clk;
input rst_n;
output pulse;
parameter Period = 14746;
reg pulse        = 1'b0;
reg [15:0] counter=16'h0000;

always@ (posedge clk )
begin
counter <= counter+1;
if(counter >= Period) begin
	counter <=0;
	pulse <= ~pulse;
end
if(counter == Period/2)
	pulse<= ~pulse;
end

endmodule
