`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/22/2025 11:02:00 AM
// Design Name:
// Module Name: tb
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


module tb();
  parameter CLK_FREQ = 100_000_000;
  parameter BAUD_RATE = 115200;

  wire uart_txd;
  reg simulationend = 1'b0;

  localparam real BIT_PERIOD = 1_000_000_000.0 / BAUD_RATE;

  top top(
    .uart_rxd(),
    .uart_txd(uart_txd));

  reg [7:0] data_out;
  integer i;

  initial begin
    //$display("[%0t] UART Monitor Started: %0d baud", $time, BAUD_RATE);
    forever begin
      // 1. Wait for Start Bit (falling edge)
      wait(uart_txd == 0);

      // 2. Jump to middle of Start Bit
      #(BIT_PERIOD / 2);

      // 3. Sample 8 Data Bits
      for (i = 0; i < 8; i = i + 1) begin
        #(BIT_PERIOD);
        data_out[i] = uart_txd;
      end

      // 4. Wait for Stop Bit
      #(BIT_PERIOD);
      if (uart_txd == 1) begin
        if (data_out == 8'h04)
          simulationend = 1'b1;
        else
          $write("%c", data_out);
      end else begin
        $write("[%0t] UART Error: Framing Error detected!", $time);
      end
    end
  end
  initial begin
    @(posedge simulationend) #20 $finish;
  end
endmodule
