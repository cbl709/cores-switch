
`timescale 1ns / 1ps
`include "uart_defines.v"

module uart_rfifo (clk, 
	rst_n, 
	data_in, 
	data_out,
// Control signals
	push, // push strobe, active high
	pop,   // pop strobe, active high
// status signals
	count,
	error_bit,
	overrun
	);


// FIFO parameters
parameter fifo_width = `UART_FIFO_REC_WIDTH;
parameter fifo_depth = `UART_FIFO_DEPTH;
parameter fifo_pointer_w = `UART_FIFO_POINTER_W;
parameter fifo_counter_w = `UART_FIFO_COUNTER_W;

input						clk;
input						rst_n;
input						push;
input						pop;

input	[`UART_FIFO_REC_WIDTH-1:0]	data_in; //11 bits
output	[`UART_FIFO_REC_WIDTH-1:0]	data_out;//11 bits

output	[fifo_counter_w-1:0]	count;
output							error_bit;
output							overrun;

wire [7:0] data8_out;
// flags FIFO
reg	[2:0]	fifo[fifo_depth-1:0];
reg    		overrun=0;

// FIFO pointers
reg	[fifo_pointer_w-1:0]	top=0;
reg	[fifo_pointer_w-1:0]	bottom=0;
reg	[fifo_counter_w-1:0]	count=0;

wire [fifo_pointer_w-1:0] top_plus_1 = top + 1'b1;
wire push_logic;
assign push_logic=push&(count<fifo_depth);

/////////
integer i;

raminfr #(fifo_pointer_w,8,fifo_depth) rfifo  
        (.clk(clk), 
		.we(push_logic), 
		.top(top), 
		.bottom(bottom), 
		.dat_i(data_in[`UART_FIFO_REC_WIDTH-1:`UART_FIFO_REC_WIDTH-8]), 
		.dat_o(data8_out)
		); 

always @(posedge clk ) // synchronous FIFO
begin
		case ({push, pop})
		2'b10 : if (count<fifo_depth)  // overrun condition
			begin
				top       <= #1 top_plus_1;
				fifo[top] <= #1 data_in[2:0];
				count     <= #1 count + 1'b1;
			end
		2'b01 : if(count>0)
			begin
                fifo[bottom] <= #1 0;
				bottom   <= #1 bottom + 1'b1;
				count	 <= #1 count - 1'b1;
			end
		2'b11 : begin
				bottom   <= #1 bottom + 1'b1;
				top       <= #1 top_plus_1;
				fifo[top] <= #1 data_in[2:0];
		        end
    default: ;
		endcase

end   // always

/////overrun logic
always @(posedge clk ) // synchronous FIFO
begin
  if(push & ~pop & (count==fifo_depth))
    overrun   <= #1 1'b1;
end   // always


// please note though that data_out is only valid one clock after pop signal
assign data_out = {data8_out,fifo[bottom]};
assign error_bit= |fifo[top];

endmodule
