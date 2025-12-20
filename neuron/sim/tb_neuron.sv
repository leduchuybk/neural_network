`timescale 1ns / 1ps
module tb_neuron();

  parameter dataWidth = 16;
  parameter numWeight = 10;

  logic                 tb_clk  = 1'b0;
  logic                 tb_rstn = 1'b0;
  logic [dataWidth-1:0] tb_mInput            =  'd0;
  logic                 tb_mInputValid       = 1'b0;
  logic [dataWidth-1:0] tb_mWeight           =  'd0;
  logic                 tb_mWeightValid      = 1'b0;
  logic [31:0]          tb_mBias             =  'd0;
  logic                 tb_mBiasValid        = 1'b0;
  logic [31:0]          tb_config_layer_num  =  'd0;
  logic [31:0]          tb_config_neuron_num =  'd0;
  logic [dataWidth-1:0] tb_mOutput;
  logic                 tb_mOutputValid;
  real realOut;
  logic enb0, enb1, enb2;
  // function binary to fixed point
  task binary_to_real;
        input  signed [31:0] q_in;  // Signed input to preserve two's complement
        input  int dataWidth;
        input  int intWidth;
        output real dec_out;
        begin
            // 1. Convert the signed binary into a real floating-point number
            // 2. Divide by 2^number of fraction bit (16384) to shift the binary point to the left
            dec_out = $itor(q_in) / 2**(dataWidth-intWidth);
        end
  endtask
  // Clock
  always tb_clk = #5 ~tb_clk;

  // Driver
  initial begin
    #112 tb_rstn <= 1'b1;
    for (int i = 0; i < numWeight; i ++) begin
      @(posedge tb_clk)
      tb_mInputValid <= 1'b1;
`ifdef SIGMOID
      tb_mInput      <= 16'b0000_0000_0000_0000; // value = 0.00
`else
      tb_mInput      <= 16'b0000_0000_1010_0100; // value = +0.01 (1 for sign, 1 for integer)
`endif
      @(posedge tb_clk) tb_mInputValid <= 1'b0;
    end
  end

  //Monitor
  always @(posedge tb_clk) begin
    enb0 <= dut.enb0;
    enb1 <= dut.enb1;
    enb2 <= dut.enb2;
    if (enb0) begin
      binary_to_real(dut.mul, 32, 4, realOut);
      $display("[%0t] mul = 0x%h (%f)", $time, dut.mul, realOut);
    end
    if (enb1) begin
      binary_to_real(dut.comboAdd,  32, 4, realOut);
      $display("[%0t] comboAdd = 0x%h (%f)", $time, dut.comboAdd, realOut);
    end
    if (enb2) begin
      binary_to_real(dut.bias ,  32, 4, realOut);
      $display("bias = 0x%h (%0f)", dut.bias, realOut);
      binary_to_real(dut.sum ,  32, 4, realOut);
      $display("[%0t] Sum = 0x%h (%f)", $time, dut.sum, realOut);
    end
    if (tb_mOutputValid) begin
      binary_to_real(tb_mOutput, dataWidth, 2, realOut);
      $display("[%0t] mOutput = 0x%h (%f)", $time, tb_mOutput, realOut);
      #20 $finish();
    end
  end

  neuron #(
    .layerNo       (0),
    .neuronNo      (0),
    .numWeight     (numWeight),
    .dataWidth     (dataWidth),
    .sigmoidSize   (10),
    .weightIntWidth(2),
`ifdef SIGMOID
    .actType       ("sigmoid"),
`else
    .actType       ("relu"),
`endif
    .biasFile      ("src/sigmoid_function/b_4_12.mif"),
    .weightFile    ("src/sigmoid_function/w_2_14.mif"),
    .sigFile       ("src/sigmoid_function/sigContent.mif")
  ) dut (
    .clk               (tb_clk              ),
    .rstn              (tb_rstn             ),
    .mInput            (tb_mInput           ),
    .mInputValid       (tb_mInputValid      ),
    .mWeight           (tb_mWeight          ),
    .mWeightValid      (tb_mWeightValid     ),
    .mBias             (tb_mBias            ),
    .mBiasValid        (tb_mBiasValid       ),
    .config_layer_num  (tb_config_layer_num ),
    .config_neuron_num (tb_config_neuron_num),
    .mOutput           (tb_mOutput          ),
    .mOutputValid      (tb_mOutputValid     )
  );

endmodule
