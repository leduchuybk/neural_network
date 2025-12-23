//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (lin64) Build 6299465 Fri Nov 14 12:34:56 MST 2025
//Date        : Mon Dec 22 20:33:01 2025
//Host        : huyld-GF63-Thin-9RCX running 64-bit Ubuntu 22.04.5 LTS
//Command     : generate_target bd_wrapper.bd
//Design      : bd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module bd_wrapper
   (Interrupt_0,
    M0_AXI_0_araddr,
    M0_AXI_0_arprot,
    M0_AXI_0_arready,
    M0_AXI_0_arvalid,
    M0_AXI_0_awaddr,
    M0_AXI_0_awprot,
    M0_AXI_0_awready,
    M0_AXI_0_awvalid,
    M0_AXI_0_bready,
    M0_AXI_0_bresp,
    M0_AXI_0_bvalid,
    M0_AXI_0_rdata,
    M0_AXI_0_rready,
    M0_AXI_0_rresp,
    M0_AXI_0_rvalid,
    M0_AXI_0_wdata,
    M0_AXI_0_wready,
    M0_AXI_0_wstrb,
    M0_AXI_0_wvalid,
    M_AXIS_MM2S_0_tdata,
    M_AXIS_MM2S_0_tkeep,
    M_AXIS_MM2S_0_tlast,
    M_AXIS_MM2S_0_tready,
    M_AXIS_MM2S_0_tvalid,
    aresetn,
    clk_out,
    usb_uart_rxd,
    usb_uart_txd);
  input [0:0]Interrupt_0;
  output [31:0]M0_AXI_0_araddr;
  output [2:0]M0_AXI_0_arprot;
  input M0_AXI_0_arready;
  output M0_AXI_0_arvalid;
  output [31:0]M0_AXI_0_awaddr;
  output [2:0]M0_AXI_0_awprot;
  input M0_AXI_0_awready;
  output M0_AXI_0_awvalid;
  output M0_AXI_0_bready;
  input [1:0]M0_AXI_0_bresp;
  input M0_AXI_0_bvalid;
  input [31:0]M0_AXI_0_rdata;
  output M0_AXI_0_rready;
  input [1:0]M0_AXI_0_rresp;
  input M0_AXI_0_rvalid;
  output [31:0]M0_AXI_0_wdata;
  input M0_AXI_0_wready;
  output [3:0]M0_AXI_0_wstrb;
  output M0_AXI_0_wvalid;
  output [31:0]M_AXIS_MM2S_0_tdata;
  output [3:0]M_AXIS_MM2S_0_tkeep;
  output M_AXIS_MM2S_0_tlast;
  input M_AXIS_MM2S_0_tready;
  output M_AXIS_MM2S_0_tvalid;
  output [0:0]aresetn;
  output clk_out;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire [0:0]Interrupt_0;
  wire [31:0]M0_AXI_0_araddr;
  wire [2:0]M0_AXI_0_arprot;
  wire M0_AXI_0_arready;
  wire M0_AXI_0_arvalid;
  wire [31:0]M0_AXI_0_awaddr;
  wire [2:0]M0_AXI_0_awprot;
  wire M0_AXI_0_awready;
  wire M0_AXI_0_awvalid;
  wire M0_AXI_0_bready;
  wire [1:0]M0_AXI_0_bresp;
  wire M0_AXI_0_bvalid;
  wire [31:0]M0_AXI_0_rdata;
  wire M0_AXI_0_rready;
  wire [1:0]M0_AXI_0_rresp;
  wire M0_AXI_0_rvalid;
  wire [31:0]M0_AXI_0_wdata;
  wire M0_AXI_0_wready;
  wire [3:0]M0_AXI_0_wstrb;
  wire M0_AXI_0_wvalid;
  wire [31:0]M_AXIS_MM2S_0_tdata;
  wire [3:0]M_AXIS_MM2S_0_tkeep;
  wire M_AXIS_MM2S_0_tlast;
  wire M_AXIS_MM2S_0_tready;
  wire M_AXIS_MM2S_0_tvalid;
  wire [0:0]aresetn;
  wire clk_out;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  bd bd_i
       (.Interrupt_0(Interrupt_0),
        .M0_AXI_0_araddr(M0_AXI_0_araddr),
        .M0_AXI_0_arprot(M0_AXI_0_arprot),
        .M0_AXI_0_arready(M0_AXI_0_arready),
        .M0_AXI_0_arvalid(M0_AXI_0_arvalid),
        .M0_AXI_0_awaddr(M0_AXI_0_awaddr),
        .M0_AXI_0_awprot(M0_AXI_0_awprot),
        .M0_AXI_0_awready(M0_AXI_0_awready),
        .M0_AXI_0_awvalid(M0_AXI_0_awvalid),
        .M0_AXI_0_bready(M0_AXI_0_bready),
        .M0_AXI_0_bresp(M0_AXI_0_bresp),
        .M0_AXI_0_bvalid(M0_AXI_0_bvalid),
        .M0_AXI_0_rdata(M0_AXI_0_rdata),
        .M0_AXI_0_rready(M0_AXI_0_rready),
        .M0_AXI_0_rresp(M0_AXI_0_rresp),
        .M0_AXI_0_rvalid(M0_AXI_0_rvalid),
        .M0_AXI_0_wdata(M0_AXI_0_wdata),
        .M0_AXI_0_wready(M0_AXI_0_wready),
        .M0_AXI_0_wstrb(M0_AXI_0_wstrb),
        .M0_AXI_0_wvalid(M0_AXI_0_wvalid),
        .M_AXIS_MM2S_0_tdata(M_AXIS_MM2S_0_tdata),
        .M_AXIS_MM2S_0_tkeep(M_AXIS_MM2S_0_tkeep),
        .M_AXIS_MM2S_0_tlast(M_AXIS_MM2S_0_tlast),
        .M_AXIS_MM2S_0_tready(M_AXIS_MM2S_0_tready),
        .M_AXIS_MM2S_0_tvalid(M_AXIS_MM2S_0_tvalid),
        .aresetn(aresetn),
        .clk_out(clk_out),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
