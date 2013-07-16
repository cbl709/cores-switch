`timescale 1ns / 1ps
`include "uart_defines.v"

module uart(
			clk,
			rst_n,
			lcr,       //line control register
			dl,        
			tdr,
			tf_push,
			rf_pop,
			rf_push_pulse,   // receive a new data
			srx_pad_i, // uart in
			stx_pad_o, // uart out
			tf_count,
			rf_count,
			rdr
			);
	input clk;
	input rst_n;
	input [7:0] lcr;
	input [7:0] dl;
	input [7:0] tdr;
	input tf_push;
	input rf_pop;
	input srx_pad_i; // uart in
	output [7:0] rdr;
	output [`UART_FIFO_COUNTER_W-1:0] tf_count;
	output [`UART_FIFO_COUNTER_W-1:0] rf_count;
	output  rf_push_pulse;
	
	reg    [7:0] rdr =8'h00;
	output stx_pad_o;// uart out
	
/////// Frequency divider signals/////////////////////
wire dlab;					//divisor latch access bit
reg enable =1'b0;
reg [7:0]   dlc=8'h00;
wire  		start_dlc;
assign 		dlab= lcr[`UART_LC_DL];
assign 		start_dlc= dlab&(dl!=0); // dlab==1 and dl!=0

always @(posedge clk ) 
begin
	
	  if(start_dlc) begin
		if (dlc==0)           
  			dlc <= #1 dl - 1;               // reload counter
		else
			dlc <= #1 dlc - 1;              // decrement counter
	 end
end

// Enable signal generation logic
always @(posedge clk )
begin
		if ( ~(|dlc) &start_dlc)     //  dlc==0 &start_dlc
			enable <= #1 1'b1;
		else
			enable <= #1 1'b0;
end


///////////////transmitter////////////////////
wire serial_out;
wire [`UART_FIFO_COUNTER_W-1:0] 				tf_count;
wire [2:0] 										tstate;
assign stx_pad_o= serial_out;
uart_transmitter transmitter(
							.clk(clk),
							.dat_i(tdr),
							.lcr(lcr),
							.rst_n(rst_n),
							.tf_push(tf_push),
							.enable(enable),
							.tf_count(tf_count),
							.stx_pad_o(serial_out)
							);														
///////////////////////////
// Synchronizing and sampling serial RX input
wire srx_pad;
  uart_sync_flops    i_uart_sync_flops
  (
    .rst_i           (rst_n),
    .clk_i           (clk),
    .stage1_rst_i    (1'b0),
    .stage1_clk_en_i (1'b1),
    .async_dat_i     (srx_pad_i),
    .sync_dat_o      (srx_pad)
  );
  defparam i_uart_sync_flops.width      = 1;
  defparam i_uart_sync_flops.init_value = 1'b1;
  
// Receiver Instance

wire rf_pop; // this signal is used to pop the data from receiver fifo
wire serial_in;
wire [9:0] counter_t;
wire [`UART_FIFO_REC_WIDTH-1:0] 			rf_data_out; // 11 bits
wire rf_error_bit;
wire rf_overrun;
wire rf_push_pulse;
assign serial_in=srx_pad;  ///test
//assign serial_in= serial_out;

uart_receiver receiver(.clk(clk), 
					   .rst_n(rst_n),
					   .lcr(lcr), 
					   .rf_pop(rf_pop),
						.rf_push_pulse(rf_push_pulse),
					   .srx_pad_i(serial_in), 
					   .enable(enable),  
					   .rf_count(rf_count), 
					   .rf_data_out(rf_data_out), 
					   .rf_error_bit(rf_error_bit), // 
					   .rf_overrun(rf_overrun)
					   
					   );
											   
/////asynchronous read  the rx_fifo data 
always@( rf_data_out or lcr )
begin
	rdr={rf_data_out[10:3]};
end


endmodule
	
