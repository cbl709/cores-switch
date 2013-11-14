

`define CPUA_MEM_BEGIN  22'h2000  //CPUA 可写的2048(512*4)字节地址 0x22008000
`define CPUA_MEM_END    22'h21ff  //                     
`define CPUB_MEM_BEGIN  22'h2200  //CPUB 可写的2048字节地址 0x22008800
`define CPUB_MEM_END    22'h23ff  //                                   

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

wire CPUA_we;
wire CPUB_we;

assign CPUA_we= A_we&&(A_addr>=`CPUA_MEM_BEGIN)&&(A_addr<=`CPUA_MEM_END);
assign CPUB_we= B_we&&(B_addr>=`CPUB_MEM_BEGIN)&&(B_addr<=`CPUB_MEM_END);



 share_mem  share_mem(
                     .addra(A_addr[9:0]),
                     .addrb(B_addr[9:0]),
                     .clka(A_clk),
                     .clkb(B_clk),
                     .dina(A_write_data),
                     .dinb(B_write_data),
                     .douta(A_read_data),
                     .doutb(B_read_data),
                     .wea(CPUA_we),
                     .web(CPUB_we)
                     );





















endmodule
