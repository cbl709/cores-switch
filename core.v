
`include "uart_defines.v"
module core(
            clk,
            io_a,
            io_b,
            force_swi, //指令切换指示，只有==1时切换板才会根据com_swi数据切换电路。否则根据心跳信号自动切换
            com_swi,   //command_switch,保存指令切换数据, ==0 指令切换到A，==1 切换到B
            error,
            reset_A,
            reset_B,
            
            switch,
            
            led1,
            led2,
            led3,
            led4,
				
				GPIO_A,
				GPIO_B,
            
            srx_commA,
            srx_commB,
            stx_commA,
            stx_commB,
            
            srx_cpuA,
            srx_cpuB,
            stx_cpuA,
            stx_cpuB,
            
            com_pop,       //command pop, input signal from command module
            rec_command,   // output to command module
            tf_push_cpuAB, // input signal form command module
            tdr_cpuAB,
            com_count,
            command_time_out,
            
            
            
            sw1,
            sw2,
            sw3,
            sw4,
            sw5,
            sw6
            
            );
parameter DL= (`OSC*1000)/(16*`BAUD);

input clk; 
input io_a;
input io_b;
input force_swi;
input com_swi;
input error;   
input reset_A;
input reset_B;

input tf_push_cpuAB;
input com_pop;
output [7:0] rec_command;
input  [7:0] tdr_cpuAB;

input srx_commA;
input srx_commB;
wire srx_commA;
wire srx_commB;
output stx_commA;
output stx_commB;
output [`UART_FIFO_COUNTER_W-1:0] com_count; //command bytes count

input srx_cpuA;
input srx_cpuB;
output stx_cpuA;
output stx_cpuB;

output led1;
output led2;
output led3;
output led4;

output GPIO_A;
output GPIO_B;

output sw1;
output sw2;
output sw3;
output sw4;
output sw5;
output sw6;
output command_time_out;

output switch;           

wire io_a;
wire io_b;
assign {led3,led4}={~io_a,~io_b};  
assign {GPIO_A,GPIO_B}={~switch, switch};  

reg switch= 1'b0;         // switch==0 switch to cpu A;
				    // switch==1 switch to cpu B;

assign {sw1,sw2,sw3,sw4,sw5,sw6}= {~switch,~switch,~switch,~switch,~reset_B,~reset_A};  

/////////////// CPU A and CPU B error detection //////////////////
wire a_error;
wire b_error;
reg [7:0] a_err_num = 8'h00;	//  the number of CPU A error
reg [7:0] b_err_num = 8'h00;


assign a_error = ~io_a;
assign b_error = ~io_b;

////detect the rising edge of a_error and b_error
reg a_error_d1 = 1'b0; // a_error singnal delay 1 clk;
reg b_error_d1 = 1'b0;
reg a_error_d2 = 1'b0; // a_error singnal delay 1 clk;
reg b_error_d2 = 1'b0;
always@( posedge clk )
 begin
	a_error_d1 <= a_error;
	a_error_d2 <= a_error_d1;
	b_error_d1 <= b_error;
	b_error_d2 <= b_error_d1;
end

always@( posedge clk  )
begin
	if(a_error_d1&(~a_error_d2))   //  rising edge of a error
	a_err_num	  <= a_err_num+1;
	if(b_error_d1&(~b_error_d2))
	b_err_num	  <= b_err_num+1; //   rising edge of b error
	
/////////////////counter overflow/////////////////////////////////
	if((a_err_num==255) || (b_err_num==255)) 
    begin // prevent  error num overflow
		if(a_err_num> b_err_num) begin
		  a_err_num <=1;
		  b_err_num <=0;
		end
		else begin
		 a_err_num <=0;
		 b_err_num <=1;
		end
	end
/////////////////指令切换将错误次数清0/////
	if(force_swi) begin
	a_err_num <= 0;
	b_err_num <= 0;
	end
end

/////////////switch decision/////////////////////////////////////////////////////////
always@ ( a_error or b_error or com_swi or force_swi )
begin
	
	case({a_error, b_error, com_swi})
		3'b000: begin
					if(force_swi)
					switch <=0;	
					if(a_err_num > b_err_num)
						switch <= 1;
					if(a_err_num < b_err_num)
						switch <= 0;
				
					
					end
		3'b001: begin
					if(force_swi)
					switch <= 1;
					
					if(a_err_num > b_err_num)
						switch <= 1;
					if(a_err_num < b_err_num)
						switch <= 0;
					
				end
					
					
		3'b010: switch <= 0;
		3'b011: switch <= 0;
		3'b100: switch <= 1;
		3'b101: switch <= 1;
		3'b110: switch <= 0;
		3'b111: switch <= 1;
	endcase
	
end


/////////////led logic //////////////////////////////////////

/*			led1    led2 
			 on		off	  cpu A working
			 off	on    cpu B working
			 on		on    command error
			 			*/

reg led1 = 1'b1;
reg led2 = 1'b1;
wire error;
always@ (switch or error )
begin
	case({switch, error})
		2'b00: begin
					led1<=0;
					led2<=1;
				 end
		2'b01: begin
					led1<=0;
					led2<=0;
				end
		2'b10: begin
					led1<=1;
					led2<=0;
				end
		2'b11:begin
					led1<=0;
					led2<=0;
				end
	endcase		
end


///////communicate port A or communicate port B send command frame to com_indentify module////// 

reg comm_sel = 1'b0;	
wire [`UART_FIFO_COUNTER_W-1:0] commA_rf_count;
wire [`UART_FIFO_COUNTER_W-1:0] commB_rf_count;
wire commandA_flag; //接commandA串口的 rf-push-pulse，为1时表示接收到新的一字节数据
wire commandB_flag; //接commandB串口的 rf-push-pulse，为1时表示接收到新的一字节数据


reg [63:0] commA_cnt =64'h0;
reg [63:0] commB_cnt =64'h0;
reg        time_out_A=0;
reg        time_out_B=0;
wire       command_time_out;
assign     command_time_out= time_out_A&time_out_B;
parameter MAX_IDLE_T =`GAP_T*160*DL;// 帧之间的传输间隔为GAP-T 字节,8N1

////如果链路在GAP-T(4)  字节内没有接收到新的数据，则置位time out
always@ (posedge clk)
begin
  if(~commandA_flag) //链路A无接收到新数据 
  commA_cnt <= commA_cnt+1;
   else
    commA_cnt <=0;
    
  if(~commandB_flag) //链路B无接收到新数据
   commB_cnt <= commB_cnt+1;
   else
    commB_cnt <=0;
    
  if(commA_cnt>= MAX_IDLE_T)
    time_out_A <=1;
  else
    time_out_A <=0;
    
  if(commB_cnt>= MAX_IDLE_T)
    time_out_B <=1;
  else
    time_out_B <=0;
  
end

////链路A B都time out判断接收到的数据帧字节数，判断是否需要切换链路
always@(command_time_out)
begin
 if(command_time_out)
  begin
    if(commA_rf_count>= commB_rf_count)
     comm_sel <=0;
    else
     comm_sel <=1;
  end
    
end


reg [`UART_FIFO_COUNTER_W-1:0] com_count    =`UART_FIFO_COUNTER_W'd0; //command bytes count
reg [7:0]                      rec_command  =8'h00;
wire [7:0]                      commA_rdr;
wire [7:0]                      commB_rdr;
reg                            commA_rf_pop =1'b0;
reg                            commB_rf_pop =1'b0;
always@(comm_sel)
begin
  case (comm_sel)
	 1'b0:			// use communication port A
	     begin
	       rec_command	    = commA_rdr;
	       com_count     	= commA_rf_count;
	       commA_rf_pop		= com_pop;
	       commB_rf_pop		= com_pop;
			 
	     end
     1'b1: begin              // use comm port B
           rec_command	    = commB_rdr;
	       com_count     	= commB_rf_count;
	       commB_rf_pop		= com_pop;
	       commA_rf_pop		= com_pop;
        end	
  endcase
end


/////////host CPU send data to comm port A and comm port B////////////////////
reg  rec_data = 1'b1;
wire srx_cpuA;
wire srx_cpuB;
wire stx_commA;
wire stx_commB;
always@(posedge clk)
begin
   if(~switch)
     rec_data= srx_cpuA;
   else
     rec_data= srx_cpuB;
end

assign stx_commA = rec_data;
assign stx_commB = rec_data;

uart comm_A(
			.clk(clk),
			.rst_n(rst_n),
			.lcr(8'b10000011),       //line control register
			.dl(DL),        
			.tdr(),
			.tf_push(1'b0),
			.rf_pop(commA_rf_pop),
			.rf_push_pulse(commandA_flag),
			.tf_count(),
			.rf_count(commA_rf_count),
			.srx_pad_i(srx_commA), // uart in
			.stx_pad_o(),// uart out
			.rdr(commA_rdr)
			);
uart comm_B(
			.clk(clk),
			.rst_n(rst_n),
			.lcr(8'b10000011),       //line control register
			.dl(DL),        
			.tdr(),
			.tf_push(1'b0),
			.rf_pop(commB_rf_pop),
			.rf_push_pulse(commandB_flag),
			.tf_count(),
			.rf_count(commB_rf_count),
			.srx_pad_i(srx_commB), // uart in
			.stx_pad_o(),// uart out
			.rdr(commB_rdr)
			);
            
uart uart_cpuA(
			.clk(clk),
			.rst_n(rst_n),
			.lcr(8'b10000011),       //line control register
			.dl(DL),        
			.tdr(tdr_cpuAB),
			.tf_push(tf_push_cpuAB),
			.rf_pop(1'b0),
			.tf_count(),
			.rf_count(),
			.srx_pad_i(1'b1), 			// uart in
			.stx_pad_o(stx_cpuA),	// uart out
			.rdr()
			);
uart uart_cpuB(
			.clk(clk),
			.rst_n(rst_n),
			.lcr(8'b10000011),       //line control register
			.dl(DL),        
			.tdr(tdr_cpuAB),
			.tf_push(tf_push_cpuAB),
			.rf_pop(1'b0),
			.tf_count(),
			.rf_count(),
			.srx_pad_i(1'b1), 			// uart in
			.stx_pad_o(stx_cpuB),	// uart out
			.rdr()
			);

            
            
            
            
            
            
            
endmodule
