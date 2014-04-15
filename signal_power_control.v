`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:30:57 03/28/2014 
// Design Name: 
// Module Name:    signal_power_control 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
// �����л�����ź��л����ϵ�״̬

//////////////////////////////////////////////////////////////////////////////////
`include "uart_defines.v"         
module signal_power_control
   (
       clk,
		 
		 debug_mode,
        //// signals switch 
        heartbeat_A,
        heartbeat_B,
        cmd_swi,
        force_swi,
        
        ////power control
        cmd_power_on_A,
        cmd_power_on_B,
        force_power_control_A,
        force_power_control_B,
    
        
        ///output signals
        switch,
        cur_power_on_A_flag,
        cur_power_on_B_flag,
		  
		  CPUA_fail,
		  CPUB_fail

    );
     
        input clk;
		  input debug_mode;
        input heartbeat_A;
        input heartbeat_B;
        input cmd_swi;
        input force_swi;
        ////power control
        input cmd_power_on_A;
        input cmd_power_on_B;
        input force_power_control_A;
        input force_power_control_B;
        
        ///output signals
        output switch;
        output cur_power_on_A_flag;
        output cur_power_on_B_flag;
		  
		  output CPUA_fail;
		  output CPUB_fail;
        
reg switch=0;
//Ĭ��A���ϵ���Ϊ������B���ϵ���Ϊ���û�
reg next_power_on_A_flag=1;
reg next_power_on_B_flag=0;

reg cur_power_on_A_flag=1;
reg cur_power_on_B_flag=0;

always@(posedge clk)
begin
  cur_power_on_A_flag <=next_power_on_A_flag;
  cur_power_on_B_flag <=next_power_on_B_flag;
end

reg A_fail_flag=0;
reg B_fail_flag=0;
reg [63:0] cnt_a=0;
reg [63:0] cnt_b=0;

wire CPUA_fail;
wire CPUB_fail;

wire CPUA_fail_flag;
wire CPUB_fail_flag;

//////////force_power_control_X delay 1clk/////
reg force_power_control_A_d=0;
reg force_power_control_B_d=0;

always@(posedge clk)
begin
	force_power_control_A_d <= force_power_control_A;
	force_power_control_B_d <= force_power_control_B;
end



/////////counter/////////

always @(posedge clk )
begin
    if(CPUA_fail_flag&~force_power_control_A&~force_power_control_A_d&~debug_mode)
      cnt_a <= cnt_a+1;
     else
      cnt_a <= 0;
      
    if(CPUB_fail_flag&~force_power_control_B&~force_power_control_B_d&~debug_mode)
      cnt_b <= cnt_b+1;
    else
      cnt_b <= 0;
end


assign CPUA_fail= cnt_a>= `FAIL_TIME*`OSC ; 
assign CPUB_fail= cnt_b>= `FAIL_TIME*`OSC ;


assign CPUA_fail_flag= ((~heartbeat_A & cur_power_on_A_flag)|A_fail_flag)&~debug_mode; //A�������ϵ�״̬�����ڷǵ���״̬��û��⵽�������ж�A��ʧЧ      
assign CPUB_fail_flag= ((~heartbeat_B & cur_power_on_B_flag)|B_fail_flag)&~debug_mode; //B�������ϵ�״̬�����ڷǵ���״̬��û��⵽�������ж�B��ʧЧ  

//�ź��л�����
always@(posedge clk)
begin
  if(force_swi)
    switch <=  cmd_swi;
  else
    case({CPUA_fail, CPUB_fail})
     2'b00: ;           //   
	  2'b01: switch <=0; //B��ʧЧ���ź��л���A��
     2'b10: switch <=1; //A��ʧЧ���ź��л���B��
     2'b00: ;           //
     default: ;
    endcase  
end



//�ϵ���Ʋ���
always@(posedge clk)
begin

////////////ָ��ǿ���ϵ��ϵ����////////////
  if(force_power_control_A|force_power_control_B|force_power_control_A_d|force_power_control_B_d)
  begin
    if(force_power_control_A|force_power_control_A_d)
       begin
         A_fail_flag          <=0;
         next_power_on_A_flag <= cmd_power_on_A;
        end
        
     if(force_power_control_B|force_power_control_B_d)
      begin
        B_fail_flag <=0;
       next_power_on_B_flag <= cmd_power_on_B;
      end

     end
     
  else
    case({CPUA_fail, CPUB_fail})
     2'b00: ;           
     2'b01: begin
             next_power_on_B_flag <=0; //B���ϵ磬A���ϵ�
             next_power_on_A_flag <=1;
             B_fail_flag          <=1; //��¼B������״̬
              end
     2'b10: begin
             next_power_on_A_flag <=0; //A���ϵ磬B���ϵ�
             next_power_on_B_flag <=1;
             A_fail_flag          <=1;
              end
     2'b11: ;
                                    
     default: ;
    endcase  
end





    


endmodule
