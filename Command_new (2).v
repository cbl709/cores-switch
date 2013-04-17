`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:58:36 11/27/2012 
// Design Name: 
// Module Name:    Command 
// Project Name: 
// Target Devices: 
// Tool versions: 

// Description: This module is used to identify the command frame send from the Control Center
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`include "uart_defines.v"
module command(      clk,
                     rst_n,
                     rdr,
                     rf_counter,
                     switch,        // working status, switch==0 CPU A is the host else CPU B is the host
                     status,
                     rf_pop,
                     tf_push,
                     tdr,
                     error,     // receive an error command
                     com_swi,   //com_swi ==0 switch to A else switch to B
                     reset_a_signal,
                     reset_b_signal,
                     power_on_A,
                     power_on_B,
                     force_swi  // force_swi=1 means a switch command is send to switch_board
                    );
input clk;
input rst_n;
input [7:0] rdr;
input switch;
input [`UART_FIFO_COUNTER_W-1:0] rf_counter;
output rf_pop;
output tf_push;
output error;
output com_swi;
output [3:0] status;
output [7:0] tdr;
output reset_a_signal;
output reset_b_signal;
output power_on_A;
output power_on_B;
output force_swi;

reg rf_pop       = 1'b0;
reg tf_push      = 1'b0;
reg [7:0] adder  = 8'h00;
reg com_swi      = 1'b0;
reg error        = 1'b0;
reg [7:0] fifo [7:0]; // fifo store 1 command frame(8 bytes)
reg [7:0] tdr    =8'h00;
reg reset_a      =1'b0;
reg reset_b      =1'b0;
reg power_on_A   =1'b1;
reg power_on_B   =1'b1; 
reg force_swi    =1'b0;


reg [15:0] byte_count    = 16'd0;
reg [2:0] dly           = 3'd0;

wire data_flag;
assign data_flag = (rf_counter>=`UART_FIFO_COUNTER_W'd1);


////接收到一个数据立刻转发给CPU
always@ (posedge clk)
begin
if(data_flag) begin //接收到数据
    tdr <= rdr;    
    tf_push <= 1; 
    rf_pop  <= 1;
end
if(tf_push)
  tf_push <=0;
if(rf_pop)
  rf_pop  <= 0;

end


//通讯链路未接收到数据时间计数，用来判定帧间隔
parameter MAX_IDLE_T = 2*16*10;  // 帧之间的间隔应该大于4个字节传输时间
reg [31:0] idle_cnt=32'h00000000;
reg  cmd_start = 1'b0;
reg  cmd_end   = 1'b0;
always @(posedge clk )
begin
    if(~data_flag)//接收FIFO为空时使能计时器
      idle_cnt <= idle_cnt+1;
    else 
      idle_cnt <= 0;
      
      //////////////////
      
      if(idle_cnt>= MAX_IDLE_T) begin
        idle_cnt <= 0;
        case({cmd_start,cmd_end})
        2'b00: begin
                  cmd_start <= 1'b1;
                  cmd_end   <= 1'b0;
                 
                 end
        2'b10: begin
                  cmd_end   <= 1'b1;
                end
        2'b11: begin
                 cmd_start <= 1'b0;
                 cmd_end   <= 1'b0;
                end
        2'b01:  begin    // error state, return to default state
                 cmd_start <= 1'b0;
                 cmd_end   <= 1'b0;
                end
        endcase
        end
end

always@(posedge clk)
begin
if(~cmd_start&~cmd_end)
begin
				  force_swi     <=0;
                  adder          <=0;
                  reset_a       <=0;
                  reset_b       <=0;
                  byte_count    <=0;
                  power_on_A    <=1;
                  power_on_B    <=1;
                  force_swi     <=0;
 
                  fifo[0]       <=0;
                  fifo[1]       <=0;
                  fifo[2]       <=0;
                  fifo[3]       <=0;
                  fifo[4]       <=0;
                  fifo[5]       <=0;
                  fifo[6]       <=0;
                  fifo[7]       <=0;
end


 if(cmd_start&~cmd_end&tf_push) begin //一个命令帧开始，并且未结束
      byte_count       <= byte_count+1;
      if(byte_count<8)
      fifo[byte_count] <= rdr;
      else
      adder <= fifo[2]+fifo[3]+fifo[4]+fifo[5];
    end
 
 if(cmd_start&cmd_end&(byte_count==16'd8)) begin //一个帧结束，并且该数据帧为8字节
 ////////////帧校验//////////////////
   if(  (fifo[0]==8'heb) & (fifo[1]==8'h90) 
      & (fifo[6]==8'h09) & (fifo[7]== 8'hd7)
      & (fifo[3]==8'hab) & (adder==8'h00))
     begin
      case(fifo[4])
        8'h0a:begin 
                com_swi <= 0;
                force_swi <=1;
              end
        8'h0b: begin
                com_swi   <= 1;
                force_swi <=1;
                end
        8'ha0: begin
                if(switch)                  // CPU A is not working
                    begin
                    reset_a <=1;            // reset CPU A
                    com_swi <=1;            // set CPU B to be the host CPU
                    force_swi <= 1;         // added in 2013-3-25
                    end
                                                        // CPU A is working, ignore this command
                end
        8'hb0: begin
                    if(~switch) // CPU B is not working
                        begin
                        reset_b <=1; // reset CPU B
                        com_swi <=0; // set CPU A to be the host CPU
                        force_swi <= 1;         // added in 2013-3-25
                        end
                                        // CPU B is working, ignore this command
                        end
        8'hab: begin
                    reset_a <= 1;
                    reset_b <= 1;
                    com_swi <= 0;
                    force_swi <= 1;         // added in 2013-3-25
                end
        8'hba: begin
                    reset_a <= 1;
                    reset_b <= 1;
                    com_swi <= 1;
                    force_swi <= 1;         // added in 2013-3-25
                end
        8'haa: begin
                    if(switch) begin  // CPU A is not working 
                        power_on_A <=1;
                        com_swi    <= 0;
                               end
                end
        8'h55: begin
                    if(power_on_A) // CPU A is power on
                    power_on_A <= 0; // turn off CPU A
                end
        
        8'hbb: begin
                    if(~switch) begin
                    power_on_B <=1;
                    com_swi    <= 1;
                                end
                end
        8'h44: begin
                    if(power_on_B) // CPU B is power on
                    power_on_B <= 0; // turn off CPU B
               end
        default: begin
                    com_swi <=0;
                    reset_a <=0;
                    reset_b <=0;
                    power_on_A <=1;
                    power_on_B <=1;
                end
        endcase
     
     end
      
     end
   
 
end



///////CPU reset signal generation//////////////
parameter Reset_Period=`OSC*`RESET_PERIOD;
reg reset_a_signal = 1'b0;  // "1" reset CPU A
reg reset_b_signal = 1'b0;
reg cnt_a_en       = 1'b0;
reg cnt_b_en       = 1'b0;
reg cnt_a_rst      = 1'b1;
reg cnt_b_rst      = 1'b1;
reg [31:0] cnt_a   = 32'h00000000;
reg [31:0] cnt_b   = 32'h00000000;
always @(posedge clk )
begin
      if(reset_a) begin
        reset_a_signal <= 1;
        cnt_a_en       <= 1;
        cnt_a_rst      <= 0;
        end
        
      if(reset_b) begin
        reset_b_signal <= 1;
        cnt_b_en       <= 1;
        cnt_b_rst      <= 0;
        end
        
      if(cnt_a>=Reset_Period)
          begin
            reset_a_signal <= 0;
            cnt_a_en       <= 0;
            cnt_a_rst      <= 1;
          end
          
          if(cnt_b>=Reset_Period)
          begin
            reset_b_signal <= 0;
            cnt_b_en       <= 0;
            cnt_b_rst      <= 1;
          end
    
end

always @(posedge clk )
begin
    if(cnt_a_en)
      cnt_a <= cnt_a+1;
    if(cnt_a_rst)
      cnt_a <= 0;
      
    if(cnt_b_en)
      cnt_b <= cnt_b+1;
    if(cnt_b_rst)
      cnt_b <= 0;
end


endmodule
