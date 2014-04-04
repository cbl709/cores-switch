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

parameter Period = `OSC;		// 	


reg [63:0] time_counter     =64'h0000;
reg [31:0] rise_match_time  =32'h0000;
reg [31:0] fall_match_time  =32'h0000;
//reg io                      =1'b1; //初始状态设为检测到心跳，防止AB机刚启动时出现混乱//edit in 2013-3-5

//////////////////detect 1khz 50% duty pwm signal ///////
reg pwm_d1                  =1'b0;
reg pwm_d2                  =1'b0;
reg start                   =1'b0;
reg start_d1                =1'b0; // start多加一个clk延时用来判断波形是否正确
reg start_d2                =1'b0;
always@ (posedge clk)
begin
 pwm_d1 <= pwm;
 pwm_d2 <= pwm_d1;
 start_d1 <= start;
 start_d2 <= start_d1;
end

wire rise_edge;
wire fall_edge;

reg freq_right             =1'b1;
reg duty_right             =1'b1;

assign rise_edge = pwm_d1&(~pwm_d2);
assign fall_edge = ~pwm_d1&pwm_d2;

always@ (posedge clk )
begin
	
	if(~start&rise_edge) begin	//检测到上升沿，时钟计数器time_counter开始计时
		start				 <= 1;
		
	end
	
	if(start&fall_edge) begin  //检测到下降沿，记录下降沿时
	fall_match_time   <= time_counter;
	end
	
	if(start&rise_edge) begin  //检测到上升沿，停止计数器，并记录上升沿时间
		rise_match_time <= time_counter;
		start			    <= 0;
	end
	
	if(~start_d2)
	begin
	  fall_match_time <= 0;
	  rise_match_time <= 0;
	end
	
	
	 			
end

always@(posedge clk )
begin
		if(start)
		time_counter <= time_counter+1;
		if(~start_d1)
		time_counter <= 32'b0;
end

always@(posedge clk )
begin
    if(~start_d1) begin     // start信号结束后延迟一个clk，这个clk用来判断波形
		if( (rise_match_time>=(Period-50)) && (rise_match_time <= (Period+50)) )//
			freq_right <= 1;  // frequency is 1khz, right
		else
			freq_right <= 0;
			
		if( (fall_match_time>=(Period/2-50)) && (fall_match_time <= (Period/2+50)) )	
			duty_right <=1;  // duty is 50%,righ
		else
			duty_right <=0;	
	end  // end of start_d1
	
end
wire io_tmp;
wire timer_overflow = time_counter>=Period+100;
assign io_tmp= freq_right&duty_right;


//// io_tmp==1 for more than DETECTION_TIME period, io=1;
/*reg [31:0] io_high_counter =32'h00000000;
reg [31:0] io_low_counter  =32'h00000000;
always@(posedge clk )
begin
		if(io_tmp) begin
			io_high_counter <= io_high_counter+1;
			io_low_counter <= 0;
			end
		else begin
			io_high_counter <= 0;
			io_low_counter <= io_low_counter+1;
		 end
		if(io_high_counter >= `DETECTION_TIME*Period) begin
			io <=1;
			io_high_counter <= 0;
		end
		if(io_low_counter >=  `DETECTION_TIME*Period) begin
			io <=0;
			io_low_counter <= 0;
		end
			
end*/

assign io=io_tmp;

endmodule
