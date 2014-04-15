

`define CPUA_MEM_BEGIN  22'h2000  //CPUA 可写的2048(512*4)字节地址 0x22008000
`define CPUA_MEM_END    22'h21ff  //                     
`define CPUB_MEM_BEGIN  22'h2200  //CPUB 可写的2048字节地址 0x22008800
`define CPUB_MEM_END    22'h23ff  //      
`define SWITCH_BOARD_MEM 22'h2400 // 切换板信息空间 0x2209000                             

module share_memory(
                    A_clk,
                    A_addr,
                    A_read_data,
                    A_write_data,
                    A_re,
                    A_we,
                    
                    B_clk,
                    B_addr,
                    B_read_data,
                    B_write_data,
                    B_re,
                    B_we,
						  
						  CPUA_fail,
						  CPUB_fail
                   );
                   
input         A_clk;
input  [21:0] A_addr;
output [31:0] A_read_data;
input  [31:0] A_write_data;
input         A_re;
input         A_we;

input         B_clk;
input  [21:0] B_addr;
output [31:0] B_read_data;
input  [31:0] B_write_data;
input         B_re;
input         B_we;

input         CPUA_fail;
input         CPUB_fail;


reg [31:0] A_read_data;
reg [31:0] B_read_data;

wire [31:0] A_out_data;
wire [31:0] B_out_data;

reg  [31:0] A_write_data_reg;
reg  [31:0] B_write_data_reg;

wire CPUA_we;
wire CPUB_we;

assign CPUA_we= A_we&(A_addr>=`CPUA_MEM_BEGIN)&(A_addr<=`CPUA_MEM_END);
assign CPUB_we= B_we&(B_addr>=`CPUB_MEM_BEGIN)&(B_addr<=`CPUB_MEM_END);


share_mem  share_mem(
                     .addra(A_addr[9:0]),
                     .addrb(B_addr[9:0]),
                     .clka(A_clk),
                     .clkb(B_clk),
                     .dina(A_write_data),
                     .dinb(B_write_data),
                     .douta(A_out_data),
                     .doutb(B_out_data),           
                     .wea(CPUA_we),
                     .web(CPUB_we)
                     );
                     
reg [31:0] switch_board_info=32'hab; //切换板信息空间，CPU A B 只能对该空间进行读取操作 

always@*
begin
  case({CPUA_fail, CPUB_fail})
  2'b00: switch_board_info <=32'hab; // cpu AB correct
  2'b01: switch_board_info <=32'haf; // cpu A correct, cpu B fail
  2'b10: switch_board_info <=32'hfb; // cpu A fail, cpu B correct
  2'b11: switch_board_info <=32'hff; // cpu AB fail
  endcase
end

always@(posedge A_clk)
begin
   if(A_addr == `SWITCH_BOARD_MEM)
	A_read_data <=switch_board_info;
	else
   A_read_data <=A_out_data;
end

always@(posedge B_clk)
begin
 if(B_addr == `SWITCH_BOARD_MEM)
	B_read_data <=switch_board_info;
	else
 B_read_data <= B_out_data;
end





















endmodule
