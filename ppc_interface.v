`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:43:22 10/25/2012 
// Design Name: 
// Module Name:    ppc_interface 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ppc_interface(
      clk,
      cs_n,
      oe_n,
      we_n,
      rd_wr,
      ebi_addr,  // connect to 
      addr,     // ingnore  A31,A30
      re_o,
      we_o
    );
     
//////IO///////////////////
    input           clk;
    input           cs_n;
    input           oe_n;
    input [3:0]     we_n;
    input           rd_wr;
    input [23:0]    ebi_addr; // connect to A31~A8
    output[21:0]    addr;    // 
    output          re_o;
    output          we_o;
/////////////////////////////     

wire  [21:0] addr;  
wire re;
wire we;

assign we =  ~rd_wr & ~cs_n&(we_n!=4'b1111); // 
assign re = rd_wr & ~cs_n&(we_n==4'b1111)  ; //

reg re_d1;
reg re_d2;
reg we_d1;
reg we_d2;

////通过2个D触发器进行同步操作
always@ (posedge clk)
begin
  re_d1 <= re;
  re_d2 <= re_d1;
  we_d1 <= we;
  we_d2 <= we_d1;
end

wire re_o;
wire we_o;

assign re_o = re;//re_d2;
assign we_o = we;//we_d2;

assign addr[21:0]=ebi_addr[23:2];
      

endmodule
