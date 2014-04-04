
`include "uart_defines.v"
module core(
            clk,
            rst_n,
            io_a,
            io_b,
            force_swi, //ָ���л�ָʾ��ֻ��==1ʱ�л���Ż����cmd_swi�����л���·��������������ź��Զ��л�
            cmd_swi,   //command_switch,����ָ���л�����, ==0 ָ���л���A��==1 �л���B
            error,
                
            cmd_power_on_A,
            cmd_power_on_B,
            force_power_control_A,
            force_power_control_B,
				
				debug_mode,
				
				CPUA_fail,
				CPUB_fail,
                
            power_on_A_flag, //A���ϵ��ϵ��־
            power_on_B_flag,
            
            switch,
            
            led1,
            led2,
            led3,
            led4,
            led5,
				led6,
                
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
            command_time_out_d
            
            );
            
parameter DL= (`OSC*1000)/(16*`BAUD);
input clk;
input rst_n;   
input io_a;
input io_b;
input force_swi;
input cmd_swi;
input error;   

input cmd_power_on_A;
input cmd_power_on_B;
input force_power_control_A;
input force_power_control_B;
input debug_mode;

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
output led5;
output led6;

output GPIO_A;
output GPIO_B;

output command_time_out_d;
output switch;           
output power_on_A_flag;
output power_on_B_flag;
output CPUA_fail;
output CPUB_fail;


wire switch;              // switch==0 signals switch to cpu A;
                          // switch==1 signals switch to cpu B;
                                  

/*
   �ź��л����ϵ����ģ��
*/

signal_power_control signal_power_control
   (
       .clk(clk),
		 .debug_mode(debug_mode),
        //// signals switch 
        .heartbeat_A(io_a),
        .heartbeat_B(io_b),
        .cmd_swi(cmd_swi),
        .force_swi(force_swi),
        
        ////power control
        .cmd_power_on_A(cmd_power_on_A),
        .cmd_power_on_B(cmd_power_on_B),
        .force_power_control_A(force_power_control_A),
        .force_power_control_B(force_power_control_B),
    
        
        ///output signals
        .switch(switch),
        .cur_power_on_A_flag( power_on_A_flag),
        .cur_power_on_B_flag( power_on_B_flag),
		  
		  .CPUA_fail(CPUA_fail),
		  .CPUB_fail(CPUB_fail)

    );





/////////////led logic //////////////////////////////////////

/*          led1    led2 
             on     off   cpu A working
             off    on    cpu B working
             
             led5 on  command error
             led5 off command right
                        */

// �͵�ƽ����led
reg led1 = 1'b1;
reg led2 = 1'b1;
reg led5 = 1'b1;
reg led6 = 1'b1;
wire error;
always@ (switch or error or debug_mode )
begin
    led1= switch;
    led2= ~switch;
    led5= ~error;
	 led6= ~debug_mode;
end

wire io_a;
wire io_b;
assign {led3,led4}={~io_a,~io_b};  
assign {GPIO_A,GPIO_B}={~switch, switch};  

///////communicate port A or communicate port B send command frame to com_indentify module////// 

reg comm_sel = 1'b0;    
wire [`UART_FIFO_COUNTER_W-1:0] commA_rf_count;
wire [`UART_FIFO_COUNTER_W-1:0] commB_rf_count;
wire commandA_flag;  //������·A��rf-push-pulse�źţ�
wire commandB_flag;


reg [63:0] commA_cnt =64'h0;
reg [63:0] commB_cnt =64'h0;
reg        time_out_A=0;
reg        time_out_B=0;
reg [9:0]  data_num_A=0; //��·A�յ���������
reg [9:0]  data_num_B=0; //��·B�յ���������
wire       command_time_out;
reg        command_time_out_d=0;
assign     command_time_out= time_out_A&time_out_B;
parameter MAX_IDLE_T =`GAP_T*160*DL;// ֮֡��Ĵ�����ΪGAP_T �ֽ�,8N1

always@(posedge clk)
begin
 command_time_out_d <= command_time_out;
end

always@ (posedge clk)
begin
  if(~commandA_flag)   //��·A����
   commA_cnt <= commA_cnt+1;
   else                //��·A���յ�������
     begin
      commA_cnt <=0;
      data_num_A <=data_num_A+1;
     end
    
  if(~commandB_flag) 
   commB_cnt <= commB_cnt+1;
   else begin
    commB_cnt <=0;
    data_num_B <= data_num_B+1;
    end
    
  if(commA_cnt>= MAX_IDLE_T)
    time_out_A <=1;
  else
    time_out_A <=0;
    
  if(commB_cnt>= MAX_IDLE_T)
    time_out_B <=1;
  else
    time_out_B <=0;
    
  if(command_time_out_d)
   begin
     data_num_A <=0;
     data_num_B <=0;
   end
  
end


always@(posedge clk)
begin
 if(command_time_out)
  begin
    if(data_num_A> data_num_B)
     comm_sel <=0;
    if(data_num_A< data_num_B)
     comm_sel <=1;
  end
    
end


reg [`UART_FIFO_COUNTER_W-1:0] com_count    =`UART_FIFO_COUNTER_W'd0; //command bytes count
reg [7:0]                      rec_command  =8'h00;
wire [7:0]                      commA_rdr;
wire [7:0]                      commB_rdr;
reg                            commA_rf_pop =1'b0;
reg                            commB_rf_pop =1'b0;
always@(comm_sel or commA_rdr or commA_rf_count or commB_rdr or commB_rf_count)
begin
  case (comm_sel)
     1'b0:          // use communication port A
         begin
           rec_command      = commA_rdr;
           com_count        = commA_rf_count;
           commA_rf_pop     = com_pop;
           commB_rf_pop     = com_pop;
             
         end
     1'b1: begin              // use comm port B
           rec_command      = commB_rdr;
           com_count        = commB_rf_count;
           commB_rf_pop     = com_pop;
           commA_rf_pop     = com_pop;
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
            .tf_count(),
            .rf_count(commA_rf_count),
            .rf_push_pulse(commandA_flag),
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
            .rf_push_pulse(commandB_flag),
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
            .srx_pad_i(1'b1),           // uart in
            .stx_pad_o(stx_cpuA),   // uart out
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
            .srx_pad_i(1'b1),           // uart in
            .stx_pad_o(stx_cpuB),   // uart out
            .rdr()
            );

            
            
            
            
            
            
            
endmodule
