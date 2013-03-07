`timescale 1ns / 1ps
`include "uart_defines.v"
/// chang log:

module uart_tfifo (clk, 
	rst_n, data_in, data_out,
// Control signals
	push, // push strobe, active high
	pop,   // pop strobe, active high
// status signals
	count
	);


// FIFO parameters
parameter fifo_width = `UART_FIFO_WIDTH;//8
parameter fifo_depth = `UART_FIFO_DEPTH;//16
parameter fifo_pointer_w = `UART_FIFO_POINTER_W;//4
parameter fifo_counter_w = `UART_FIFO_COUNTER_W;//5

input				clk;
input				rst_n;
input				push;
input				pop;
input	[fifo_width-1:0]	data_in;

output	[fifo_width-1:0]	data_out;
output	[fifo_counter_w-1:0]	count;
wire	[fifo_width-1:0]	data_out;

// FIFO pointers
reg	[fifo_pointer_w-1:0]	top;
reg	[fifo_pointer_w-1:0]	bottom;
reg	[fifo_counter_w-1:0]	count;
wire [fifo_pointer_w-1:0] top_plus_1 = top + 1'b1;
wire push_logic;
assign push_logic=push&(count<fifo_depth);

raminfr #(fifo_pointer_w,fifo_width,fifo_depth) tfifo  //?
        (   .clk(clk), 
			.we(push_logic), 
			.top(top), 
			.bottom(bottom), 
			.dat_i(data_in), 
			.dat_o(data_out)
		); 


always @(posedge clk or negedge rst_n) // synchronous FIFO
begin
	if (~rst_n)
	begin
		top		<= #1 0;
		bottom		<= #1 1'b0;
		count		<= #1 0;
	end
  else
	begin
		case ({push, pop})
		2'b10 : if (count<fifo_depth)  // overrun condition
			begin
				top       <= #1 top_plus_1;
				count     <= #1 count + 1'b1;
			end
		2'b01 : if(count>0)
			begin
				bottom   <= #1 bottom + 1'b1;
				count	 <= #1 count - 1'b1;
			end
		2'b11 : begin
				bottom   <= #1 bottom + 1'b1;
				top       <= #1 top_plus_1;
		        end
    default: ;
		endcase
	end
end   // always

endmodule
