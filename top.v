`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:55:26 10/25/2012 
// Design Name: 
// Module Name:    top 
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
// test github
//////////////////////////////////////////////////////////////////////////////////
`include "uart_defines.v"
module top(
	  clk,
	  rst_n,
	  
	  srx_a,
	  srx_b,
	  srx_c,
	  srx_d,
	  
	  pwm_a,
	  pwm_b,
	  
	  stx_a,
	  stx_b,
	  stx_c,
	  stx_d,
	  
	  led1,
	  led2,
	  
	  sw1,
	  sw2,
	  sw3,
	  sw4,
	  sw5,
	
	  reset_A,
	  reset_B,
	  power_on_A,
	  power_on_B,
	  
	  //test signal////
	  pulse_a,
	  pulse_b,
	  io_a,
	  io_b
    );
input clk;
input rst_n;
input srx_a;
input srx_b;
input srx_c;
input srx_d;

input pwm_a;
input pwm_b;

output stx_a;
output stx_b;
output stx_c;
output stx_d;


output led1;
output led2;
output sw1;
output sw2;
output sw3;
output sw4;
output sw5;

output reset_A;
output reset_B;
output power_on_A;
output power_on_B;

/////test signal///////
output pulse_a;
output pulse_b;
output io_a;
output io_b;

parameter DL= (`OSC*1000)/(16*`BAUD);

wire io_a;
wire io_b;
wire force_swi;



wire [3:0]	status;

reg switch;     // switch==0 switch to cpu A;
				// switch==1 switch to cpu B;

assign {sw1,sw2,sw3,sw4,sw5}= {~switch,~switch,~switch,~switch,~switch};
					
								
/////////////// CPU A and CPU B error detection //////////////////
wire a_error;
wire b_error;
reg [7:0] a_err_num;	//  the number of CPU A error
reg [7:0] b_err_num;
///edit in 2013-3-5
/*always@( posedge clk or negedge rst_n)
begin
	if(~rst_n)
	 begin
	  a_error<=1;  //change 1 to 0 edit in 2013-3-5
	  b_error<=1;
	 
	 end
	else begin
		
		 a_error <= ~io_a;
		 b_error <= ~io_b;
		
	end	 
end*/

assign a_error = ~io_a;
assign b_error = ~io_b;

////detect the rising edge of a_error and b_error
reg a_error_d1; // a_error singnal delay 1 clk;
reg b_error_d1;
reg a_error_d2; // a_error singnal delay 1 clk;
reg b_error_d2;
always@( posedge clk or negedge rst_n)
if(~rst_n)
begin
a_error_d1 <=0;
b_error_d1 <=0;
a_error_d2 <=0;
b_error_d2 <=0;
end
else begin
	a_error_d1 <= a_error;
	a_error_d2 <= a_error_d1;
	b_error_d1 <= b_error;
	b_error_d2 <= b_error_d1;
end

always@( posedge clk or negedge rst_n )
begin
	if(~rst_n)
	begin
	a_err_num <=0;
	b_err_num <=0;
	end
	else begin
	if(a_error_d1&(~a_error_d2))
	a_err_num	  <= a_err_num+1;
	if(b_error_d1&(~b_error_d2))
	b_err_num	  <= b_err_num+1;
	
	/////////////////counter overflow/////////////////////////////////
	if((a_err_num==255) || (b_err_num==255)) begin // prevent  error num overflow
		if(a_err_num> b_err_num) begin
		  a_err_num <=1;
		  b_err_num <=0;
		end
		else begin
		 a_err_num <=0;
		 b_err_num <=1;
		end
	end
	/////////////////指令切换或者A B机未启动完成都将错误次数清0/////
	if(force_swi) begin
	a_err_num <= 0;
	b_err_num <= 0;
	end
	
	
	end		
end

/////////////switch decision/////////////////////////////////////////////////////////
wire com_swi;
always@ ( a_error or b_error or com_swi or force_swi )
begin
	
	case({a_error, b_error, com_swi})
		3'b000: begin
					if(force_swi)
					switch <=0;	
					if(a_err_num > b_err_num)
						switch <= 1;
					if(a_err_num < b_err_num)
						switch <= 0;
				
					
					end
		3'b001: begin
					if(force_swi)
					switch <= 1;
					
					if(a_err_num > b_err_num)
						switch <= 1;
					if(a_err_num < b_err_num)
						switch <= 0;
					
				end
					
					
		3'b010: switch <= 0;
		3'b011: switch <= 0;
		3'b100: switch <= 1;
		3'b101: switch <= 1;
		3'b110: switch <= 0;
		3'b111: switch <= 1;
	endcase
	//end
end

/////////////led logic //////////////////////////////////////

/*			led1    led2 
			 on		off	cpu A working
			 off		on    cpu B working
			 on		on    command error
			 			*/

reg led1;
reg led2;
wire error;
always@ (switch or error )
begin
	case({switch, error})
		2'b00: begin
					led1<=0;
					led2<=1;
				 end
		2'b01: begin
					led1<=0;
					led2<=0;
				end
		2'b10: begin
					led1<=1;
					led2<=0;
				end
		2'b11:begin
					led1<=0;
					led2<=0;
				end
	endcase		
end


////////uart_a or uart_b send command frame to com_indentify module////// 
reg com_sel;	
wire [`UART_FIFO_COUNTER_W-1:0] rf_count0;
wire [`UART_FIFO_COUNTER_W-1:0] rf_count1;

always@ (posedge clk or negedge rst_n)
begin
	if(~rst_n)
	  com_sel<=0;			// com_sel=0 use uart_a else use uart_b
	 else begin
		if((rf_count0 >=8)&&(rf_count1<8))
			com_sel<=0;
		if((rf_count1 >=8)&&(rf_count0<8))
			com_sel<=1;
	 
	 end
end

wire [7:0] rdr_a;
wire [7:0] rdr_b;
reg  [7:0] rdr_ab;
wire rf_pop_ab;
reg rf_pop0;
reg rf_pop1;
reg [`UART_FIFO_COUNTER_W-1:0] rf_count_ab;
always@( posedge clk )
begin
	  if(~com_sel)			// use uart_a
	     begin
	       rdr_ab			= rdr_a;
	       rf_count_ab	= rf_count0;
	       rf_pop0			= rf_pop_ab;
	       rf_pop1			= 0;
			 
	     end
	  else begin			// use uart_b
				rdr_ab		 = rdr_b;
				rf_count_ab	 = rf_count1;
				rf_pop1		 = rf_pop_ab;
				rf_pop0		 = 0;
				
			 end	
end

/////////host CPU send data to uart_a and uart_b////////////////////
reg srx_ab; 
always@ (posedge clk )
begin
			if(~switch)
		   srx_ab = srx_c ;  // CPU A is host cpu
			else
		   srx_ab = srx_d ;  // CPU B is host cpu
		
end

assign stx_a = srx_ab;
assign stx_b = srx_ab;


wire [7:0] tdr0;
wire [7:0] tdr1;
    
uart uart_a(
			.clk(clk),
			.rst_n(rst_n),
			.lcr(8'b10000011),       //line control register
			.dl(DL),        
			.tdr(tdr0),
			.tf_push(tf_push0),
			.rf_pop(rf_pop0),
			.tf_count(tf_count0),
			.rf_count(rf_count0),
			.srx_pad_i(srx_a), // uart in
			.stx_pad_o(),// uart out
			.rdr(rdr_a)
			);
uart uart_b(
			.clk(clk),
			.rst_n(rst_n),
			.lcr(8'b10000011),       //line control register
			.dl(DL),        
			.tdr(tdr1),
			.tf_push(tf_push1),
			.rf_pop(rf_pop1),
			.tf_count(tf_count1),
			.rf_count(rf_count1),
			.srx_pad_i(srx_b), // uart in
			.stx_pad_o(),// uart out
			.rdr(rdr_b)
			);
/////// uart_c : communicate between switch borad and CPU A;
///////	uart_c : communicate between switch borad and CPU B;		

wire [7:0] tdr_cd;
wire 		  tf_push_cd;

uart uart_c(
			.clk(clk),
			.rst_n(rst_n),
			.lcr(8'b10000011),       //line control register
			.dl(DL),        
			.tdr(tdr_cd),
			.tf_push(tf_push_cd),
			.rf_pop(rf_pop2),
			.tf_count(tf_count2),
			.rf_count(rf_count2),
			.srx_pad_i(1'b1), 			// uart in
			.stx_pad_o(stx_c),	// uart out
			.rdr(rdr2)
			);
uart uart_d(
			.clk(clk),
			.rst_n(rst_n),
			.lcr(8'b10000011),       //line control register
			.dl(DL),        
			.tdr(tdr_cd),
			.tf_push(tf_push_cd),
			.rf_pop(0),
			.tf_count(tf_count3),
			.rf_count(),
			.srx_pad_i(1'b1), 			// uart in
			.stx_pad_o(stx_d),	// uart out
			.rdr(rdr3)
			);

command com_identify( .clk(clk),
			   .rst_n(rst_n),
			   .rdr(rdr_ab),
			   .rf_counter(rf_count_ab),
				.switch(switch),
			   .rf_pop(rf_pop_ab),
			   .tf_push(tf_push_cd),
			   .tdr(tdr_cd),
			   .error(error),  	// receive an error command
			   .com_swi(com_swi),
				.reset_a_signal(reset_A),
				.reset_b_signal(reset_B),
				.power_on_A(power_on_A),
				.power_on_B(power_on_B),
				.force_swi(force_swi)
				);
	 
	
pulse_detection CPU_A_PWM (.clk(clk),
							.rst_n(rst_n),
							.pwm(pwm_a),
							.io(io_a)
							);	 
pulse_detection CPU_B_PWM (.clk(clk),
							.rst_n(rst_n),
							.pwm(pwm_b),
							.io(io_b)
							);	 
							
pulse_gen  signal_a ( .clk(clk),
							 .rst_n(rst_n),
							 .pulse(pulse_a) );
							 
pulse_gen  signal_b ( .clk(clk),
							 .rst_n(rst_n),
							 .pulse(pulse_b) );

endmodule
