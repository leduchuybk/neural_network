`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/22/2025 05:15:50 PM
// Design Name:
// Module Name: top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module top(
  input  logic uart_rxd,
  output logic uart_txd
);
  logic [31:0] tdata;
  logic        tready;
  logic        tvalid;
  logic        intr;
  logic aresetn;
  logic clk;
  logic [31:0] s_axi_araddr;
  logic [2:0]  s_axi_arprot;
  logic        s_axi_arready;
  logic        s_axi_arvalid;
  logic [31:0] s_axi_awaddr;
  logic  [2:0] s_axi_awprot;
  logic        s_axi_awready;
  logic        s_axi_awvalid;
  logic        s_axi_bready;
  logic [1:0]  s_axi_bresp;
  logic        s_axi_bvalid;
  logic [31:0] s_axi_rdata;
  logic        s_axi_rready;
  logic [1:0]  s_axi_rresp;
  logic        s_axi_rvalid;
  logic [31:0] s_axi_wdata;
  logic        s_axi_wready;
  logic [3:0]  s_axi_wstrb;
  logic        s_axi_wvalid;

  bd_wrapper bd_wrapper(
    .M0_AXI_0_araddr(s_axi_araddr),
    .M0_AXI_0_arprot(s_axi_arprot),
    .M0_AXI_0_arready(s_axi_arready),
    .M0_AXI_0_arvalid(s_axi_arvalid),
    .M0_AXI_0_awaddr(s_axi_awaddr),
    .M0_AXI_0_awprot(s_axi_awprot),
    .M0_AXI_0_awready(s_axi_awready),
    .M0_AXI_0_awvalid(s_axi_awvalid),
    .M0_AXI_0_bready(s_axi_bready),
    .M0_AXI_0_bresp(s_axi_bresp),
    .M0_AXI_0_bvalid(s_axi_bvalid),
    .M0_AXI_0_rdata(s_axi_rdata),
    .M0_AXI_0_rready(s_axi_rready),
    .M0_AXI_0_rresp(s_axi_rresp),
    .M0_AXI_0_rvalid(s_axi_rvalid),
    .M0_AXI_0_wdata(s_axi_wdata),
    .M0_AXI_0_wready(s_axi_wready),
    .M0_AXI_0_wstrb(s_axi_wstrb),
    .M0_AXI_0_wvalid(s_axi_wvalid),
    .Interrupt_0(intr),
    .M_AXIS_MM2S_0_tdata(tdata),
    .M_AXIS_MM2S_0_tkeep(),
    .M_AXIS_MM2S_0_tlast(),
    .M_AXIS_MM2S_0_tready(tready),
    .M_AXIS_MM2S_0_tvalid(tvalid),
    .usb_uart_rxd(uart_rxd),
    .usb_uart_txd(uart_txd),
    .aresetn(aresetn),
    .clk_out(clk)
  );

  dnn #(
    .C_S_AXI_DATA_WIDTH(32),
    .C_S_AXI_ADDR_WIDTH(32)
  ) dut(
    .s_axi_aclk(clk),
    .s_axi_aresetn(aresetn),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awprot(3'b000),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(4'b1111),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bresp(),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(3'b000),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .axis_in_data(tdata),
    .axis_in_data_valid(tvalid),
    .axis_in_data_ready(tready),
    .intr(intr)
  );
endmodule
