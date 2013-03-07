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
module command(     clk,
                     rst_n,
                     rdr,
                     rf_counter,
                     switch,        // working status, switch==0 CPU A is the host else CPU B is the host
                    
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

output [7:0] tdr;
output reset_a_signal;
output reset_b_signal;
output power_on_A;
output power_on_B;
output force_swi;

reg rf_pop;
reg tf_push;
reg [7:0] adder;
reg com_swi;
reg error;
reg [7:0] fifo [7:0]; // fifo store 1 command frame(8 bytes)
reg [7:0] tdr;
reg reset_a;
reg reset_b;
reg power_on_A;
reg power_on_B;
reg force_swi;

///修改为one-hot编码，减少状态机译码电路--edit in 2013-3-5
parameter idle          = 7'b0000001;
parameter check_start1  = 7'b0000010;
parameter check_start2  = 7'b0000100;
parameter store_frame   = 7'b0001000;
parameter check_frame   = 7'b0010000; 
parameter retransmit    = 7'b0100000;
parameter wait_status   = 7'b1000000;

reg [6:0] status;
reg [6:0] next_status;
reg [3:0] byte_count;
reg [2:0] dly;

always @(posedge clk or negedge rst_n)
begin
if(~rst_n)
  begin
  status        <=idle;
  rf_pop        <=0;
  tf_push       <=0;
  error         <=0;
  adder          =0;
  com_swi       <=0;
  byte_count    <=0;
  dly           <=0;
  reset_a       <=0;
  reset_b       <=0;
  force_swi     <= 0;
  power_on_A    <=0;
  power_on_B    <=0;
  fifo[0]       <=0;
  fifo[1]       <=0;
  fifo[2]       <=0;
  fifo[3]       <=0;
  fifo[4]       <=0;
  fifo[5]       <=0;
  fifo[6]       <=0;
  fifo[7]       <=0;
  end
 else begin
 //////////////////////check command frame ////////////////////////
 case (status)
 idle: begin 
        rf_pop        <=0;
        tf_push       <=0;
        force_swi     <=0;
        adder          =0;
        reset_a       <=0;
        reset_b       <=0;
        byte_count    <=0;
        power_on_A    <=1;
        power_on_B    <=1;
        force_swi     <= 0;
 
        fifo[0]       <=0;
        fifo[1]       <=0;
        fifo[2]       <=0;
        fifo[3]       <=0;
        fifo[4]       <=0;
        fifo[5]       <=0;
        fifo[6]       <=0;
        fifo[7]       <=0;
       
      if(rf_counter>=`UART_FIFO_COUNTER_W'd8) begin
            status      <= check_start1;  
            end
       end
check_start1: begin
               // error <= 0;
                if(rdr==8'heb) 
                next_status<=check_start2;              
                else begin
                next_status<=idle; 
                error  <=1;              // added in 2013-3-7 
                end   
                rf_pop <=1;     
                status <=wait_status;    // wait_status 是为了满足从串口中获取数据所需的时序   
              end
              
check_start2:  begin    
                  if(rdr==8'h90)         // frame head detect
                   begin
                    next_status<=store_frame;
                    byte_count<=4'd2; 
                    fifo[0]<=8'heb;
                    fifo[1]<=8'h90;
                    end
                  else begin
                    next_status<=idle;
                    error<=1;
                  end
                  rf_pop<=1;    
                  status<=wait_status;        
                end
                
store_frame:  begin 
              if(byte_count==4'd8) begin     //store frame finish 8 bytes
                next_status<=check_frame;
                adder= fifo[2]+fifo[3]+fifo[4]+fifo[5];
                end
              else begin 
              fifo[byte_count] <= rdr;
              byte_count       <=byte_count+1;
              rf_pop           <=1;
              end
              status           <=wait_status;
          end
check_frame: 
        begin               
                if((adder!=0)||(fifo[6]!=8'h09)||(fifo[7]!=8'hd7)) // frame error
                  begin
                  error<=1;
                  status <= idle;
                  end
                else begin
                error <= 0;         // command frame right
                if(fifo[3]==8'hab)  // command to switch_board
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
                    status<=retransmit;
                  end
                else begin
                   status<=retransmit;
                 
                end
            end //end of else   
            
        end

retransmit: begin
                if(byte_count!=0) begin
                tdr<=fifo[8-byte_count];
                tf_push<=1;
                byte_count<=byte_count-1;
                next_status<= retransmit;
                end
                else
                
                next_status<=idle;      
            status<= wait_status;   
            end
            
wait_status: begin
            tf_push<=0;
            rf_pop<=0;
            dly<= dly+1;
            if(dly==2) begin
              status<=next_status;
              dly<= 0;
             end            
          end
            
            
default    : status <= idle;

 endcase
 end
end


///////CPU reset signal generation//////////////
parameter Reset_Period=`OSC*`RESET_PERIOD;
reg reset_a_signal;  // "1" reset CPU A
reg reset_b_signal;
reg cnt_a_en;
reg cnt_b_en;
reg cnt_a_rst;
reg cnt_b_rst;
reg [15:0] cnt_a;
reg [15:0] cnt_b;
always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
   begin
     reset_a_signal <= 0;
     reset_b_signal <= 0;
     cnt_a_en       <= 0;
     cnt_a_rst      <= 1;
     cnt_b_en       <= 0;
     cnt_b_rst      <= 1;
   end
  else
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
end

always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
  begin
   cnt_a <= 0;
   cnt_b <= 0;
  end
  else begin
    if(cnt_a_en)
      cnt_a <= cnt_a+1;
    if(cnt_a_rst)
      cnt_a <= 0;
      
    if(cnt_b_en)
      cnt_b <= cnt_b+1;
    if(cnt_b_rst)
      cnt_b <= 0;
      
      
  end
end


endmodule
