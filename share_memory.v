

`define CPUA_MEM_BEGIN  22'h2000  //CPUA ��д��2048(512*4)�ֽڵ�ַ 0x22008000
`define CPUA_MEM_END    22'h21ff  //                     
`define CPUB_MEM_BEGIN  22'h2200  //CPUB ��д��2048�ֽڵ�ַ 0x22008800
`define CPUB_MEM_END    22'h23ff  //      
`define SWITCH_BOARD_MEM 22'h2400 // �л�����Ϣ�ռ� 0x2209000                             

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
                    B_we
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
                     
reg [31:0] switch_board_info=32'hab; //�л�����Ϣ�ռ䣬CPU A B ֻ�ܶԸÿռ���ж�ȡ���� 

always@(posedge A_clk)
begin
<<<<<<< HEAD
=======
 //if(A_addr>= `SWITCH_BOARD_MEM)
 //  A_read_data <= switch_board_info;
 // else
>>>>>>> 367bcb4e80096f9d399f969448765acceb432262
   A_read_data <=A_out_data;
end

always@(posedge B_clk)
begin
<<<<<<< HEAD
=======
// if(B_addr>= `SWITCH_BOARD_MEM)
//   B_read_data <= switch_board_info;
// else
>>>>>>> 367bcb4e80096f9d399f969448765acceb432262
 B_read_data <= B_out_data;
end





















endmodule
