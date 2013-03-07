`include "uart_defines.v"
//Following is the Verilog code for a dual-port RAM with asynchronous read. 
module raminfr   
        (clk, we, top, bottom, dat_i, dat_o); 

parameter addr_width = `UART_FIFO_POINTER_W;
parameter data_width = 8;
parameter depth = `UART_FIFO_DEPTH;

input clk;   
input we;   
input  [addr_width-1:0] top;    //top
input  [addr_width-1:0] bottom; //bottom  
input  [data_width-1:0] dat_i;   
//output [data_width-1:0] spo;   
output [data_width-1:0] dat_o;   
reg    [data_width-1:0] ram [depth-1:0]; //定义ram深度16字节

wire [data_width-1:0]  dat_o;
wire  [data_width-1:0] dat_i;   
wire  [addr_width-1:0] top;   
wire  [addr_width-1:0] bottom;   
 
  always @(posedge clk) begin   
    if (we)   
      ram[top] <= dat_i;   
  end   
//  assign spo = ram[a];   
  assign dat_o = ram[bottom];   
endmodule 

