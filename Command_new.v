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
                     
                     rdr,
                     rf_counter,
                     switch,        // working status, switch==0 CPU A is the host else CPU B is the host
                     status,
                     command_time_out,
                     rf_pop,
                     tf_push,
                     tdr,
                     error,     // receive an error command
                     com_swi,   //com_swi ==0 switch to A else switch to B
                     reset_a_signal,
                     reset_b_signal,
                     power_on_A,
                     power_on_B,
                     data_count,
                     time_out,
                     data_flag,
                     rd_en,
                     force_swi  // force_swi=1 means a switch command is send to switch_board
                    );
input clk;
input [7:0] rdr;
input switch;
input command_time_out;
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
output [9:0] data_count;
output time_out;
output data_flag;
output rd_en;

reg rf_pop       = 1'b0;
reg tf_push      = 1'b0;
reg [7:0] adder  = 8'h00;
reg com_swi      = 1'b0;
reg error        = 1'b0;
reg [7:0] cmd_fifo [7:0]; // fifo store 1 command frame(8 bytes)
reg reset_a      =1'b0;
reg reset_b      =1'b0;
reg power_on_A   =1'b1;
reg power_on_B   =1'b1; 
reg force_swi    =1'b0;


wire   data_flag;
assign data_flag=|rf_counter;//只需判断rf_counter!=0

reg time_out=0;


reg [7:0] din=8'h00;
reg rd_en=0;
reg rst=0;
reg wr_en=0;
wire [9 : 0] data_count;
wire [7 : 0] dout;
wire empty;
fifo fifo(.clk(clk),
    .din(din),
    .rd_en(rd_en),
    .rst(rst),
    .wr_en(wr_en),
    .data_count(data_count),
    .dout(dout),
    .empty(empty),
    .full()
    );

////接收到一个指令即转发给CPU,并压入指令FIFO（使用IP core生成的FIFO，1024 bytes）
reg[2:0] cycle=0;
assign tdr=rdr;         //
always@ (posedge clk)
begin
 
 if(data_flag&command_time_out)
   begin
   case(cycle) //为了满足时序,tf_push等信号只能保持一个clk
   0: begin
         tf_push <= 0;
          rf_pop  <= 0;
          wr_en   <=0;
          cycle   <=cycle+1;
       end
   1: begin   //这个延时是必须的
        cycle <= cycle+1;
      end
     
   2: begin 
          tf_push <= 1;
          rf_pop  <= 1;
          din     <= rdr;
          wr_en   <= 1;
          cycle   <=0;
          end
   
   endcase
    end
    
 else begin
   tf_push <=0;
   rf_pop  <=0;
   wr_en   <=0;
 end

end



//////////////////////////////////////////////
///////////cmd identify///////////////////////
parameter idle          = 6'b000001;
parameter check_start1  = 6'b000010;
parameter check_start2  = 6'b000100;
parameter store_frame   = 6'b001000;
parameter check_frame   = 6'b010000; 
parameter wait_status   = 6'b100000;

reg [5:0] status        = idle; //important!
reg [5:0] next_status   = idle;
reg [3:0] byte_count    = 4'd0;
reg [2:0] dly           = 3'd0;

always @(posedge clk )
begin

 //////////////////////check command frame ////////////////////////
 case (status)
 idle: begin 
        rd_en         <=0;
        force_swi     <=0;
        adder         <=0;
        reset_a       <=0;
        reset_b       <=0;
        byte_count    <=0;
        power_on_A    <=1;
        power_on_B    <=1;
        force_swi     <= 0;
        rst           <=0;
 
        cmd_fifo[0]       <=0; //控制指令FIFO
        cmd_fifo[1]       <=0;
        cmd_fifo[2]       <=0;
        cmd_fifo[3]       <=0;
        cmd_fifo[4]       <=0;
        cmd_fifo[5]       <=0;
        cmd_fifo[6]       <=0;
        cmd_fifo[7]       <=0;
        
           if((data_count==4'd8)&command_time_out&~data_flag)  //一个帧结束，接收到的是8字节指令
           begin
            next_status <= check_start1;
            rd_en  <= 1;
            status  <= wait_status;
            end
            
          if(command_time_out&(data_count!=4'd8)&~data_flag) //接收到的指令不是8字节,复位??空指令FIFO
            begin
            rst <= 1;
            end
          
       end

           
check_start1: begin
                if(dout==8'heb) begin
                next_status<=check_start2;
                rd_en <=1;    
                end           
                else begin
                next_status<=idle; 
                error  <=1;              // added in 2013-3-7
                rst    <=1; 
                end   
                status <=wait_status;    // wait_status 是为了满足获取数据时序
              end
              
check_start2:  begin    
                  if(dout==8'h90)         // frame head detect
                   begin
                    next_status<=store_frame;
                    byte_count<=4'd2; 
                    cmd_fifo[0]<=8'heb;
                    cmd_fifo[1]<=8'h90;
                    end
                  else begin
                    next_status<=idle;
                    error<=1;
                    rst  <=1;
                  end
                  rd_en<=1;    
                  status<=wait_status;        
                end
                
store_frame:  begin 
              if(byte_count==4'd8) begin     //store frame finish 8 bytes
                next_status<=check_frame;
                adder              <= cmd_fifo[2]+cmd_fifo[3]+cmd_fifo[4]+cmd_fifo[5];
                end
              else begin 
              cmd_fifo[byte_count] <= dout;
              byte_count           <=byte_count+1;
              rd_en                <=1;
              end
              status               <=wait_status;
          end
          
check_frame: 
        begin                 
            if((adder==0)&(cmd_fifo[6]==8'h09)&(cmd_fifo[7]==8'hd7))  // frame check right
                begin
                   error <=0;
                   if (cmd_fifo[3]==8'hab) // switch board ID
                    begin
                    case(cmd_fifo[4])
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
                                end
                                                        // CPU A is working, ignore this command
                            end
                        8'hb0: begin
                                if(~switch) // CPU B is not working
                                begin
                                reset_b <=1; // reset CPU B
                                com_swi <=0; // set CPU A to be the host CPU
                                end
                                        // CPU B is working, ignore this command
                                end
                        8'hab: begin
                                    reset_a <= 1;
                                    reset_b <= 1;
                                    com_swi <= 0;
                                end
                        8'hba: begin
                                    reset_a <= 1;
                                    reset_b <= 1;
                                    com_swi <= 1;
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
            else
                error <=1;
                
                rst <=1;
                status<=idle; 
        end

wait_status: begin
              rd_en<=0;
              status<=next_status;
          end
            
default    : status <= idle;
 endcase
 
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
