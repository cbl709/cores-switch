
`include "uart_defines.v"
module core(
            clk,
            rst_n,
            io_a,
            io_b,
            force_swi, //ָ���л�ָʾ��ֻ��==1ʱ�л���Ż����com_swi�����л���·��������������ź��Զ��л�
            com_swi,   //command_switch,����ָ���л�����, ==0 ָ���л���A��==1 �л���B
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
            
            
            
            sw1,
            sw2,
            sw3,
            sw4,
            sw5,
            sw6
            
            );
parameter DL= (`OSC*1000)/(16*`BAUD);

input clk;
input rst_n;   
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

output switch;           

wire io_a;
wire io_b;
assign {led3,led4}={~io_a,~io_b};  
assign {GPIO_A,GPIO_B}={~switch, switch};  

reg switch;         // switch==0 switch to cpu A;
				    // switch==1 switch to cpu B;

assign {sw1,sw2,sw3,sw4,sw5,sw6}= {~switch,~switch,~switch,~switch,~reset_A,~reset_B};  

/////////////// CPU A and CPU B error detection //////////////////
wire a_error;
wire b_error;
reg [7:0] a_err_num;	//  the number of CPU A error
reg [7:0] b_err_num;


assign a_error = ~io_a;
assign b_error = ~io_b;

////detect the rising edge of a_error and b_error
reg a_error_d1; // a_error singnal delay 1 clk;
reg b_error_d1;
reg a_error_d2; // a_error singnal delay 1 clk;
reg b_error_d2;
always@( posedge clk or negedge rst_n)
if(~rst_n)
begin
a_error_d1 <=0;
b_error_d1 <=0;
a_error_d2 <=0;
b_error_d2 <=0;
end
else begin
	a_error_d1 <= a_error;
	a_error_d2 <= a_error_d1;
	b_error_d1 <= b_error;
	b_error_d2 <= b_error_d1;
end

always@( posedge clk or negedge rst_n )
begin
	if(~rst_n)
	begin
	a_err_num <=0;
	b_err_num <=0;
	end
	else begin
	if(a_error_d1&(~a_error_d2))   //  rising edge of a error
	a_err_num	  <= a_err_num+1;
	if(b_error_d1&(~b_error_d2))
	b_err_num	  <= b_err_num+1; //   rising edge of b error
	
/////////////////counter overflow/////////////////////////////////
	if((a_err_num==255) || (b_err_num==255)) begin // prevent  error num overflow
		if(a_err_num> b_err_num) begin
		  a_err_num <=1;
		  b_err_num <=0;
		end
		else begin
		 a_err_num <=0;
		 b_err_num <=1;
		end
	end
/////////////////ָ���л������������0/////
	if(force_swi) begin
	a_err_num <= 0;
	b_err_num <= 0;
	end
	
	
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

reg led1;
reg led2;
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
reg comm_sel;	
wire [`UART_FIFO_COUNTER_W-1:0] commA_rf_count;
wire [`UART_FIFO_COUNTER_W-1:0] commB_rf_count;

always@ (posedge clk or negedge rst_n)
begin
	if(~rst_n)
	  comm_sel<=0;			               // comm_sel=0 use portA else use portB
	 else begin                            // �Ƚ��յ����ڵ���8���ֽ�ָ�����·Ϊ����·
		if((commA_rf_count >=8)&&(commB_rf_count<8))
			comm_sel<=0;
		if((commB_rf_count >=8)&&(commA_rf_count<8))
			comm_sel<=1;
	 
	 end
end

reg [`UART_FIFO_COUNTER_W-1:0] com_count; //command bytes count
reg [7:0]                      rec_command;
wire [7:0]                      commA_rdr;
wire [7:0]                      commB_rdr;
reg                            commA_rf_pop;
reg                            commB_rf_pop;
always@(comm_sel)
begin
  case (comm_sel)
	 1'b0:			// use communication port A
	     begin
	       rec_command	    = commA_rdr;
	       com_count     	= commA_rf_count;
	       commA_rf_pop		= com_pop;
	       commB_rf_pop		= 0;
			 
	     end
     1'b1: begin              // use comm port B
           rec_command	    = commB_rdr;
	       com_count     	= commB_rf_count;
	       commB_rf_pop		= com_pop;
	       commA_rf_pop		= 0;
        end	
  endcase
end


/////////host CPU send data to comm port A and comm port B////////////////////
reg  rec_data;
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