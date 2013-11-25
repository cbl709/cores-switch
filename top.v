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
      srx_a,
      srx_b,
      srx_c, //通讯链路A
      srx_d, //通讯链路B
      
      pwm_a,
      pwm_b,
      
      stx_a,
      stx_b,
      stx_c,
      stx_d,
        
        //rec_cmdA, //切换板转发的指令，通过232(moxa com7)输出,作为调试接口使用
        //rec_cmdB, //切换板转发的指令，通过232(moxa com8)输出,作为调试接口使用
      
      led1,
      led2,
      led3,
      led4,
      led5,
     // led6, //test led
      
      input_switch0,
      input_switch1,
      input_switch2,
      input0_to_A,
      input1_to_A,
      input2_to_A,
      input0_to_B,
      input1_to_B,
      input2_to_B,
      
      output_switch0,
      output_switch1,
      output_switch2,
      output0_from_A,
      output1_from_A,
      output2_from_A,
      output0_from_B,
      output1_from_B,
      output2_from_B,

      
      sw0,
      sw1,
      sw2,
      sw3,
      
     reset_A_pin_n, // 低电平复位计算机A
     reset_B_pin_n, // 低电平复位计算机B
      
     power_on_A,
     power_on_B,
     
      
      GPIO_A,
      GPIO_B,
      
      ////共享内??EBI信号//////
	
      A_clkout,
      A_cs_n,
      A_oe_n,
      A_we_n,
      A_rd_wr,
      A_ebi_data,  // connect to D31~D0
      A_ebi_addr,  // connect to A31~A8 
      
      B_clkout,
      B_cs_n,
      B_oe_n,
      B_we_n,
      B_rd_wr,
      B_ebi_data,  // connect to D31~D0
      B_ebi_addr  // connect to A31~A8
      
    
    );
input clk;

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
//output rec_cmdA;
//output rec_cmdB;

output led1;
output led2;
output led3;
output led4;
output led5;
//output led6;

output GPIO_A;
output GPIO_B;

output sw0;
output sw1;
output sw2;
output sw3;

output  reset_A_pin_n; // 低电平复位计算?鶤
output  reset_B_pin_n; // 低电平复位计算机B

output  power_on_A;
output  power_on_B;


//////////swi io pin////
input [7:0]       input_switch0;
output [7:0]      input0_to_A;
output [7:0]      input0_to_B;
input [7:0]       input_switch1;
input [7:0]       input_switch2;

output [7:0]      input1_to_A;
output [7:0]      input2_to_A;

output [7:0]      input1_to_B;
output [7:0]      input2_to_B;
      
output [7:0]      output_switch0;
input [7:0]       output0_from_A;
input [7:0]       output0_from_B;
output [7:0]      output_switch1;
output [7:0]      output_switch2;

input [7:0]      output1_from_A;
input [7:0]      output2_from_A;

input [7:0]      output1_from_B;
input [7:0]      output2_from_B;


////共享内存EBI信号//////

input            A_clkout;
input            A_cs_n;
input            A_oe_n;
input [3:0]      A_we_n;
input            A_rd_wr;
inout [31:0]     A_ebi_data;  // connect to D31~D0
input [23:0]     A_ebi_addr;  // connect to A31~A8 
      
input            B_clkout;
input            B_cs_n;
input            B_oe_n;
input [3:0]      B_we_n;
input            B_rd_wr;
inout [31:0]     B_ebi_data;  // connect to D31~D0
input [23:0]     B_ebi_addr;  // connect to A31~A8 */



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
wire command_time_out_d;

wire power_on_A;
wire power_on_B;

assign {sw0,sw1,sw2,sw3}={switch,switch,switch,switch};

/////该上电复位逻辑控制硬件相关，根据具体硬件电路修改
//assign {power_off_A,power_off_B}={~power_on_A,~power_on_B};
assign {reset_A_pin_n,reset_B_pin_n}={~reset_A,~reset_B};

//////////////////CPU A CPU B共享内存代码//////////////////////////////


////cpu and fpga inout port    
wire A_re_o;
wire A_we_o;
wire B_re_o;
wire B_we_o; 

wire [31:0] A_read_data;
wire [31:0] B_read_data;

wire [31:0] A_write_data;
wire [31:0] B_write_data;

wire [31:0] A_out_data;
wire [31:0] B_out_data;

assign A_write_data    = A_ebi_data;
assign A_ebi_data[31:0]= A_re_o? A_read_data:32'hzzzzzzzz;

assign B_write_data    = B_ebi_data;
assign B_ebi_data[31:0]= B_re_o? B_read_data:32'hzzzzzzzz;

wire [21:0] A_addr;
wire [21:0] B_addr;

ppc_interface  CPUA_interface (  
                            .clk(A_clkout),
                            .cs_n(A_cs_n),
                            .oe_n(A_oe_n),
                            .we_n(A_we_n),
                            .rd_wr(A_rd_wr),
                            .ebi_addr(A_ebi_addr),  // connect to A31~A8
                            .addr(A_addr),     // ingnore  A31,A30
                            .re_o(A_re_o),
                            .we_o(A_we_o)
                    );
                    
ppc_interface  CPUB_interface (  
                            .clk(B_clkout),
                            .cs_n(B_cs_n),
                            .oe_n(B_oe_n),
                            .we_n(B_we_n),
                            .rd_wr(B_rd_wr),
                            .ebi_addr(B_ebi_addr),  // connect to A31~A8
                            .addr(B_addr),     // ingnore  A31,A30
                            .re_o(B_re_o),
                            .we_o(B_we_o)
                    );
                          
share_memory share_memory(
                    .A_clk(A_clkout),
                    .A_addr(A_addr),
                    .A_read_data(A_read_data),
                    .A_write_data(A_write_data),
                    .A_re(A_re_o),
                    .A_we(A_we_o),                                                        
                    .B_clk(B_clkout),
                    .B_addr(B_addr),
                    .B_read_data(B_read_data),
                    .B_write_data(B_write_data),
                    .B_re(B_re_o),
                    .B_we(B_we_o)
                   );              

                   

////////switch io //////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////

//////////switch 0//////////////////////////
input_switch input_swi0(
                    .clk(clk),
                    .ctr_io(switch), // ctr_io==0 switch to CPU A else CPU B
                    .input_pin(input_switch0),
                    .input_to_A(input0_to_A),
                    .input_to_B(input0_to_B)
                    );

output_switch output_swi0(
                    .clk(clk),
                    .ctr_io(switch), // ctr_io==0 switch to CPU A else CPU B
                    .output_pin(output_switch0),
                    .output_from_A(output0_from_A),
                    .output_from_B(output0_from_B)
                    );
                    
///////////switch1 switch2///////////////


input_switch input_swi1(
                    .clk(clk),
                    .ctr_io(switch), // ctr_io==0 switch to CPU A else CPU B
                    .input_pin(input_switch1),
                    .input_to_A(input1_to_A),
                    .input_to_B(input1_to_B)
                    );
input_switch input_swi2(
                    .clk(clk),
                    .ctr_io(switch), // ctr_io==0 switch to CPU A else CPU B
                    .input_pin(input_switch2),
                    .input_to_A(input2_to_A),
                    .input_to_B(input2_to_B)
                    );

output_switch output_swi1(
                    .clk(clk),
                    .ctr_io(switch), // ctr_io==0 switch to CPU A else CPU B
                    .output_pin(output_switch1),
                    .output_from_A(output1_from_A),
                    .output_from_B(output1_from_B)
                    );
output_switch output_swi2(
                    .clk(clk),
                    .ctr_io(switch), // ctr_io==0 switch to CPU A else CPU B
                    .output_pin(output_switch2),
                    .output_from_A(output2_from_A),
                    .output_from_B(output2_from_B)
                    );

///////////////////////////////////end switch io/////////////////////////////////////////////////////////                    
////////////////////////////////////////////////////////////////////////////////////////////////////////


core core(
            .clk        (clk),
				.rst_n      (1),
            .io_a       (io_a),
            .io_b       (io_b),
            .force_swi  (force_swi),          
            .com_swi    (com_swi),   
            .error      (error),       
            .switch     (switch),        
            .led1       (led1), // cpu A is host
            .led2       (led2), // cpu B is host
            .led3       (led3), // pwm A correct
            .led4       (led4), // pwm B correct
            .led5       (led5), // command frame error
                
           .GPIO_A     (GPIO_A),
           .GPIO_B     (GPIO_B),
            
            .srx_commA  (srx_c),
            .srx_commB  (srx_d),
            
         //  .stx_commA  (stx_c),
         //   .stx_commB  (stx_d),
            
        
             .srx_cpuA   (1),
             .srx_cpuB   (1),
         //   .stx_cpuA   (rec_cmdA),//转发接收到的数据
         //   .stx_cpuB   (rec_cmdB),
            
            .com_pop    (com_pop),       //command pop, input signal from command module
            .rec_command(rec_command),   // output to command module
            .tf_push_cpuAB(tf_push_cpuAB), // input signal form command module
            .tdr_cpuAB  (tdr_cpuAB),
            .com_count  (com_count),
            
            .command_time_out_d(command_time_out_d)
            
            );

command com_identify( .clk(clk),
               .rdr(rec_command),
               .rf_counter(com_count),
               .command_time_out_d(command_time_out_d),
               .switch(switch),
               .rf_pop(com_pop),
               .tf_push(tf_push_cpuAB),
               .tdr(tdr_cpuAB),
               .error(error),   // receive an error command
               .com_swi(com_swi),
                .reset_A(reset_A),
                .reset_B(reset_B),
                .power_on_A(power_on_A),
                .power_on_B(power_on_B),
                .force_swi(force_swi)
                );
     
    
pulse_detection CPU_A_PWM (.clk(clk),
                            .pwm(1),
                            .io(io_a)
                            );   
pulse_detection CPU_B_PWM (.clk(clk),
                            .pwm(1),
                            .io(io_b)
                            );   
                            

endmodule
