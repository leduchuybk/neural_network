`timescale 1ns / 1ps
module tb_neuron();

  parameter dataWidth = 32;
  parameter numWeight = 784;

  logic                 tb_clk  = 1'b0;
  logic                 tb_rstn = 1'b0;
  logic [dataWidth-1:0] tb_mInput            = 'd0;
  logic                 tb_mInputValid       = 'b0  ;
  logic [dataWidth-1:0] tb_mWeight           = 'd0;
  logic                 tb_mWeightValid      = 1'b0 ;
  logic [31:0]          tb_mBias             = 'd0;
  logic                 tb_mBiasValid        = 1'b0 ;
  logic [31:0]          tb_config_layer_num  = 'd0;
  logic [31:0]          tb_config_neuron_num = 'd0;
  logic [dataWidth-1:0] tb_mOutput;
  logic                 tb_mOutputValid;

  // Clock
  always tb_clk = #5 ~tb_clk;

  // Driver
  initial begin
    #112 tb_rstn <= 1'b1;
    for (int i = 0; i < numWeight; i ++) begin
      @(posedge tb_clk)
      tb_mInputValid <= 1'b1;
      tb_mInput      <= i   ;
    end
    @(posedge tb_clk) tb_mInputValid <= 1'b0;
    #200 $finish();
  end

  neuron #(
    .layerNo       (0),
    .neuronNo      (0),
    .numWeight     (numWeight),
    .dataWidth     (dataWidth),
    .sigmoidSize   (10),
    .weightIntWidth(4),
    .actType       ("sigmoid"),
    .biasFile      ("src/sigmoid_function/b_1_15.mif"),
    .weightFile    ("src/sigmoid_function/w_1_15.mif"),
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
