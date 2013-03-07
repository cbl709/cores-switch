`timescale 1ns / 1ps


module uart_sync_flops
(
  // internal signals
  rst_i,
  clk_i,
  stage1_rst_i,
  stage1_clk_en_i,
  async_dat_i,
  sync_dat_o
);

parameter Tp            = 1;
parameter width         = 1;
parameter init_value    = 1'b0;

input                           rst_i;                  // reset input
input                           clk_i;                  // clock input
input                           stage1_rst_i;           // synchronous reset for stage 1 FF
input                           stage1_clk_en_i;        // synchronous clock enable for stage 1 FF
input   [width-1:0]             async_dat_i;            // asynchronous data input
output  [width-1:0]             sync_dat_o;             // synchronous data output


//
// Interal signal declarations
//

reg     [width-1:0]             sync_dat_o;
reg     [width-1:0]             flop_0;


// first stage
always @ (posedge clk_i or negedge rst_i)
begin
    if (~rst_i)
        flop_0 <= #Tp {width{init_value}};
    else
        flop_0 <= #Tp async_dat_i;    
end

// second stage
always @ (posedge clk_i or negedge rst_i)
begin
    if (~rst_i)
        sync_dat_o <= #Tp {width{init_value}};
    else if (stage1_rst_i)
        sync_dat_o <= #Tp {width{init_value}};
    else if (stage1_clk_en_i)
        sync_dat_o <= #Tp flop_0;       
end

endmodule
