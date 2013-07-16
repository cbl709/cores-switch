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
								rst_n,
								pwm,
								io
								);
input clk;
input rst_n;
input pwm;
output io;	

parameter Period = `OSC;		// use 14.7456MHZ OSC,0.001s	


reg [15:0] time_counter;
reg [15:0] rise_match_time;
reg [15:0] fall_match_time;
reg io;

//////////////////detect 1khz 50% duty pwm signal ///////
reg pwm_d1;
reg pwm_d2;
reg start;
reg start_d1; // start多加一个clk延时用来判断波形是否正确
always@ (posedge clk)
begin
 pwm_d1 <= pwm;
 pwm_d2 <= pwm_d1;
 start_d1 <= start;
end

wire rise_edge;
wire fall_edge;

reg freq_right;
reg duty_right;

assign rise_edge = pwm_d1&(~pwm_d2);
assign fall_edge = ~pwm_d1&pwm_d2;

always@ (posedge clk or negedge rst_n)
begin
	if(~rst_n) begin
	 rise_match_time   <=0;
	 fall_match_time   <=0;
	 start			   <= 0;
	 end
	else begin
	
	if(~start&rise_edge) begin	//检测到上升沿，时钟计数器time_counter开始计时
		start				 <= 1;
		
	end
	
	if(start&fall_edge) begin  //检测到下降沿，记录下降沿时间
		fall_match_time <= time_counter;
	end
	
	if(start&rise_edge) begin  //检测到上升沿，停止计数器，并记录上升沿时间
		rise_match_time <= time_counter;
		start			<= 0;
	end
	 			
	end
end

always@(posedge clk or negedge rst_n)
begin
	if(~rst_n) begin
	 time_counter   <=  16'b0;
	end
	else begin
		if(start)
		time_counter <= time_counter+1;
		if(~start_d1)
		time_counter <= 16'b0;
		
	end
end

always@(posedge clk or negedge rst_n)
begin
	if(~rst_n) begin
	 freq_right			<= 0;
	 duty_right			<= 0;
	end
	else begin  
	  if(~start_d1) begin     // start信号结束后延迟一个clk，这个clk用来判断波形 //edit in 2013-3-5
		if( (rise_match_time>=(Period-50)) && (rise_match_time <= (Period+50)) )// 允许周期左右偏差50 个clk
			freq_right <= 1;  // frequency is 1khz, right
		else
			freq_right <= 0;
			
		if( (fall_match_time>=(Period/2-50)) && (fall_match_time <= (Period/2+50)) )	
			duty_right <=1;  // duty is 50%,righ
		else
			duty_right <=0;	
	end  // end of start_d1
	
  end	//end of else		
end
wire io_tmp;
assign io_tmp= freq_right&duty_right;

//// io_tmp==1 for more than 100 period(0.1s), io=1;
reg [31:0] io_high_counter;
reg [31:0] io_low_counter;
always@(posedge clk or negedge rst_n)
begin
	if(~rst_n) begin
	io_high_counter  <= 0;
	io_low_counter   <= 0;
    
    io               <= 1;  //初始状态设为检测到心跳，防止AB机刚启动时出现混乱//edit in 2013-3-5
	end
	else begin
		if(io_tmp) begin
			io_high_counter <= io_high_counter+1;
			io_low_counter <= 0;
			end
		else begin
			io_high_counter <= 0;
			io_low_counter <= io_low_counter+1;
		 end
		if(io_high_counter >= 100*Period) begin
			io <=1;
			io_high_counter <= 0;
		end
		if(io_low_counter >= 100*Period) begin
			io <=0;
			io_low_counter <= 0;
		end
		
	end
	
end

endmodule
