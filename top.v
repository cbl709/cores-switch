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
//
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
	  led3,
	  led4,
	  
	  sw1,
	  sw2,
	  sw3,
	  sw4,
	  sw5,
	  sw6,
	  
	  GPIO_A,
	  GPIO_B,
      
      pulse_a,
      pulse_b
	
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
output led3;
output led4;

output GPIO_A;
output GPIO_B;

output sw1;
output sw2;
output sw3;
output sw4;
output sw5;
output sw6;
output pulse_a;
output pulse_b;


wire io_a;
wire io_b;
wire force_swi;
wire com_swi;
wire error;
wire reset_A;
wire reset_B;
wire switch;

wire       com_pop;
wire [7:0] rec_command;
wire       tf_push_cpuAB;
wire [7:0] tdr_cpuAB;
wire [`UART_FIFO_COUNTER_W-1:0] com_count;
wire srx_c;
wire srx_d;
wire command_time_out;




core core(
            .clk        (clk),
            .io_a       (io_a),
            .io_b       (io_b),
            .force_swi  (force_swi),          
            .com_swi    (com_swi),   
            .error      (error),
            .reset_A    (reset_A),
            .reset_B    (reset_B),
            .switch      (switch),
            
            .led1       (led1),
            .led2       (led2),
            .led3       (led3),
            .led4       (led4),
				
				.GPIO_A		(GPIO_A),
				.GPIO_B     (GPIO_B),
            
            .srx_commA  (srx_c),
            .srx_commB  (srx_d),
            .stx_commA  (stx_c),
            .stx_commB  (stx_d),
            
            .srx_cpuA   (srx_a),
            .srx_cpuB   (srx_b),
            .stx_cpuA   (stx_a),
            .stx_cpuB   (stx_b),
            
            .com_pop    (com_pop),       //command pop, input signal from command module
            .rec_command(rec_command),   // output to command module
            .tf_push_cpuAB(tf_push_cpuAB), // input signal form command module
            .tdr_cpuAB  (tdr_cpuAB),
            .com_count   (com_count),
            
            .command_time_out(command_time_out),
            
            
            .sw1        (sw1),
            .sw2        (sw2),
            .sw3        (sw3),
            .sw4        (sw4),
            .sw5        (sw5),
            .sw6        (sw6)
            
            );

command com_identify( .clk(clk),
			   .rdr(rec_command),
			   .rf_counter(com_count),
            .command_time_out(command_time_out),
            .switch(switch),
			   .status(status),
			   .rf_pop(com_pop),
			   .tf_push(tf_push_cpuAB),
			   .tdr(tdr_cpuAB),
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
