`include "uart_defines.v"
//Following is the Verilog code for a dual-port RAM with asynchronous read. 
module raminfr   
        (clk, we, top, bottom, data_in, data_out); 

parameter addr_width = `UART_FIFO_POINTER_W;
parameter data_width = 8;
parameter depth = `UART_FIFO_DEPTH;

input clk;   
input we;   
input  [addr_width-1:0] top;    //top
input  [addr_width-1:0] bottom; //bottom  
input  [data_width-1:0] data_in;    
output [data_width-1:0] data_out;  


 
/*reg    [data_width-1:0] ram [depth-1:0]; //定义ram深度16字节
  always @(posedge clk) begin   
    if (we)   
      ram[top] <= data_in;   
  end   
  assign data_out = ram[bottom]; */ 
  
  
  dual_ram dual_ram(
    .addra(top),
    .addrb(bottom),
    .clka(clk),
    .clkb(clk),
    .dina(data_in),
    .doutb(data_out),
    .wea(we));
    

   
endmodule 

