
////cbl_uart

`timescale 1ns / 1ps
`include "uart_defines.v"

module uart_receiver (
                    clk, 
                    rst_n, 
                    lcr, 
                    rf_pop,
                    srx_pad_i,
                    enable, 
                    rf_count, 
                    rf_data_out, 
                    rf_error_bit, 
                    rf_push_pulse,
                    rf_overrun 
                    );

input               clk;
input               rst_n;
input            [7:0]  lcr;
input               rf_pop;
input               srx_pad_i;
input               enable;

output  [`UART_FIFO_COUNTER_W-1:0]  rf_count;
output  [`UART_FIFO_REC_WIDTH-1:0]  rf_data_out; //11 bits
output              rf_overrun;
output              rf_error_bit;
output              rf_push_pulse;
wire                rf_push_pulse;

reg [3:0]   rstate=4'd0;
reg [3:0]   rcounter16=4'd0;
reg [2:0]   rbit_counter=3'd0;
reg [7:0]   rshift=8'd0;            // receiver shift register
reg     rparity=1'b0;           // received parity
reg     rparity_error=1'b0;
reg     rframing_error=1'b0;        // framing error flag

reg     rparity_xor=1'b0;
reg [7:0]   counter_b=8'h00;        // counts the 0 (low) signals
reg   rf_push_q=1'b0; 

// RX FIFO signals
reg     [`UART_FIFO_REC_WIDTH-1:0]              rf_data_in=0;
wire    [`UART_FIFO_REC_WIDTH-1:0]              rf_data_out;

reg                                             rf_push=0;
wire                                            rf_pop;
wire                                            rf_overrun;
wire    [`UART_FIFO_COUNTER_W-1:0]              rf_count;
wire                                            rf_error_bit; 

// RX FIFO instance
uart_rfifo #(`UART_FIFO_REC_WIDTH) fifo_rx(
    .clk(       clk     ), 
    .data_in(   rf_data_in  ),
    .data_out(  rf_data_out ),
    .push(      rf_push_pulse   ),
    .pop(       rf_pop      ),
    .count(     rf_count    ),
    .error_bit( rf_error_bit ),
    .overrun(    overrun)
);

wire        rcounter16_eq_7 = (rcounter16 == 4'd7);
wire        rcounter16_eq_0 = (rcounter16 == 4'd0);
wire        rcounter16_eq_1 = (rcounter16 == 4'd1);

wire [3:0] rcounter16_minus_1 = rcounter16 - 1'b1;

parameter  sr_idle                  = 4'd0;
parameter  sr_rec_start             = 4'd1;
parameter  sr_rec_bit               = 4'd2;
parameter  sr_rec_parity            = 4'd3;
parameter  sr_rec_stop              = 4'd4;
parameter  sr_check_parity          = 4'd5;
parameter  sr_rec_prepare           = 4'd6;
parameter  sr_end_bit               = 4'd7;
parameter  sr_ca_lc_parity          = 4'd8;
parameter  sr_wait1                 = 4'd9;
parameter  sr_push                  = 4'd10;


always @(posedge clk )
begin
  
  if (enable)
  begin
    case (rstate)
    sr_idle : begin
            rf_push                 <= #1 1'b0;
            rf_data_in              <= #1 0;
            rcounter16              <= #1 4'b1110; // 
            if (srx_pad_i==1'b0 )   // detected a pulse (start bit?)
            begin
                rstate        <= #1 sr_rec_start;
            end
        end
    sr_rec_start :  begin
            rf_push               <= #1 1'b0;
                if (rcounter16_eq_7)    // check the pulse
                    if (srx_pad_i==1'b1)   // no start bit
                        rstate <= #1 sr_idle;
                    else            // start bit detected
                        rstate <= #1 sr_rec_prepare;
                rcounter16 <= #1 rcounter16_minus_1;
            end
    sr_rec_prepare:begin
                case (lcr[/*`UART_LC_BITS*/1:0])  // number of bits in a word
                2'b00 : rbit_counter <= #1 3'b100;
                2'b01 : rbit_counter <= #1 3'b101;
                2'b10 : rbit_counter <= #1 3'b110;
                2'b11 : rbit_counter <= #1 3'b111;
                endcase
                if (rcounter16_eq_0)
                begin
                    rstate      <= #1 sr_rec_bit;
                    rcounter16  <= #1 4'b1110;
                    rshift      <= #1 0;
                end
                else
                    rstate <= #1 sr_rec_prepare;
                rcounter16 <= #1 rcounter16_minus_1;
            end
    sr_rec_bit :    begin
                if (rcounter16_eq_0)
                    rstate <= #1 sr_end_bit;
                if (rcounter16_eq_7) // read the bit
                    case (lcr[/*`UART_LC_BITS*/1:0])  // number of bits in a word
                    2'b00 : rshift[4:0]  <= #1 {srx_pad_i, rshift[4:1]};
                    2'b01 : rshift[5:0]  <= #1 {srx_pad_i, rshift[5:1]};
                    2'b10 : rshift[6:0]  <= #1 {srx_pad_i, rshift[6:1]};
                    2'b11 : rshift[7:0]  <= #1 {srx_pad_i, rshift[7:1]};
                    endcase
                rcounter16 <= #1 rcounter16_minus_1;
            end
    sr_end_bit :   begin
                if (rbit_counter==3'b0) // no more bits in word
                    if (lcr[`UART_LC_PE]) // choose state based on parity
                        rstate <= #1 sr_rec_parity;
                    else
                    begin
                        rstate <= #1 sr_rec_stop;
                        rparity_error <= #1 1'b0;  // no parity - no error :)
                    end
                else        // else we have more bits to read
                begin
                    rstate <= #1 sr_rec_bit;
                    rbit_counter <= #1 rbit_counter - 1'b1;
                end
                rcounter16 <= #1 4'b1110;
            end
    sr_rec_parity: begin
                if (rcounter16_eq_7)    // read the parity
                begin
                    rparity <= #1 srx_pad_i;
                    rstate <= #1 sr_ca_lc_parity; 
                end
                rcounter16 <= #1 rcounter16_minus_1;
            end
    sr_ca_lc_parity : begin    // rcounter equals 6
                rcounter16  <= #1 rcounter16_minus_1;
                rparity_xor <= #1 ^{rshift,rparity}; // calculate parity on all incoming data
                rstate      <= #1 sr_check_parity;
              end
    sr_check_parity: begin    // rcounter equals 5
                case ({lcr[`UART_LC_EP],lcr[`UART_LC_SP]})
                    2'b00: rparity_error <= #1  rparity_xor == 0;  // no error if parity 1
                    2'b01: rparity_error <= #1 ~rparity;      // parity should sticked to 1
                    2'b10: rparity_error <= #1  rparity_xor == 1;   // error if parity is odd
                    2'b11: rparity_error <= #1  rparity;      // parity should be sticked to 0
                endcase
                rcounter16 <= #1 rcounter16_minus_1;
                rstate <= #1 sr_wait1;
              end
    sr_wait1 :  if (rcounter16_eq_0)
            begin
                rstate <= #1 sr_rec_stop;
                rcounter16 <= #1 4'b1110;
            end
            else
                rcounter16 <= #1 rcounter16_minus_1;
    sr_rec_stop :   begin
                if (rcounter16_eq_7)    // read stop bit
                begin
                    rframing_error <= #1 !srx_pad_i; // no framing error if input is 1 (stop bit)
                    rstate <= #1 sr_push;
                end
                rcounter16 <= #1 rcounter16_minus_1;
            end
    sr_push :begin
        if(srx_pad_i )
          begin
                  rf_data_in  <= #1 {rshift, 1'b0, rparity_error, rframing_error};
                  rf_push         <= #1 1'b1;
                  rstate        <= #1 sr_idle;
          end
        else if(~rframing_error)  // There's always a framing before break_error -> wait for break or srx_pad_i
          begin
                rf_data_in  <= #1 {rshift, 1'b0, rparity_error, rframing_error};
                rf_push     <= #1 1'b1;
                rcounter16  <= #1 4'b1110;
                rstate      <= #1 sr_rec_start;
          end          
            end
    default : rstate <= #1 sr_idle;
    endcase
  end  // if (enable)
end // always of receiver 

always @ (posedge clk )
begin
    rf_push_q <= #1 rf_push;
end

assign rf_push_pulse = rf_push & ~rf_push_q; // detect the rising edge of rf_push

    
endmodule
