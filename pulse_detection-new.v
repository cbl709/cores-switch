`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:24:31 12/12/2012 
// Design Name: 
// Module Name:    pulse_detection 
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
`include "uart_defines.v"
module pulse_detection(
                                clk,
                                pwm,
                                io
                                );
input clk;
input pwm;
output io;  

parameter Period = `OSC;        //  


//////////////////detect 1khz heartbeat signal///////
reg pwm_d1                  =1'b0;
reg pwm_d2                  =1'b0;
always@ (posedge clk)
begin
 pwm_d1 <= pwm;
 pwm_d2 <= pwm_d1;
end

wire rise_edge;
wire fall_edge;
assign rise_edge = pwm_d1&(~pwm_d2);
assign fall_edge = ~pwm_d1&pwm_d2;

/////////////counter/////////////////////
reg [63:0] counter =64'h00;
always@(posedge clk)
begin
  counter <= counter+1;
  if(rise_edge)
    counter <= 0;
end

wire freq_right;
assign freq_right= counter<=Period+100;

assign io_tmp= freq_right;

// io_tmp==1 for more than DETECTION_TIME period, io=1;
reg io=1'b1;
reg [31:0] io_high_counter =32'h00000000;
reg [31:0] io_low_counter  =32'h00000000;
always@(posedge clk )
begin
        if(io_tmp) begin
            io_high_counter <= io_high_counter+1;
            io_low_counter  <= 0;
            end
        else begin
            io_high_counter <= 0;
            io_low_counter  <= io_low_counter+1;
         end
        if(io_high_counter >= `DETECTION_TIME*Period) begin
            io              <= 1;
            io_high_counter <= 0;
        end
        if(io_low_counter >=  `DETECTION_TIME*Period) begin
            io             <= 0;
            io_low_counter <= 0;
        end
            
end


endmodule
