`include "layer_parameter.sv"
module Layer1 #(
  parameter int NN = 30,
  parameter int numWeight=784,
  parameter int dataWidth=16,
  parameter int layerNum=1,
  parameter int sigmoidSize=10,
  parameter int weightIntWidth=4,
  parameter string actType="relu")
  (
    input                      clk              ,
    input                      rstn             ,
    input                      weightValid      ,
    input                      biasValid        ,
    input  [31:0]              weightValue      ,
    input  [31:0]              biasValue        ,
    input  [31:0]              config_layer_num ,
    input  [31:0]              config_neuron_num,
    input                      x_valid          ,
    input  [dataWidth-1:0]     x_in             ,
    output [NN-1:0]            o_valid          ,
    output [NN*dataWidth-1:0]  x_out
  );

  genvar i;
  generate
    for (i=0; i < NN; i++) begin : gen_neuron
      localparam string FILE_BIAS   = $sformatf("%sb_1_%0d.mif",`WB_DIR,i);
      localparam string FILE_WEIGHT = $sformatf("%sw_1_%0d.mif",`WB_DIR,i);
      localparam string FILE_SIG    = $sformatf("%ssigContent.mif",`SIG_DIR);
      neuron #(
        .layerNo       (layerNum),
        .neuronNo      (i),
        .numWeight     (numWeight),
        .dataWidth     (dataWidth),
        .sigmoidSize   (sigmoidSize),
        .weightIntWidth(weightIntWidth),
        .actType       (actType),
        .biasFile      (FILE_BIAS),
        .weightFile    (FILE_WEIGHT),
        .sigFile       (FILE_SIG)
      ) u_neuron (
        .clk               (clk              ),
        .rstn              (rstn             ),
        .mInput            (x_in             ),
        .mInputValid       (x_valid          ),
        .mWeight           (weightValue      ),
        .mWeightValid      (weightValid      ),
        .mBias             (biasValue        ),
        .mBiasValid        (biasValid        ),
        .config_layer_num  (config_layer_num ),
        .config_neuron_num (config_neuron_num),
        .mOutput           (x_out[i*dataWidth+:dataWidth]),
        .mOutputValid      (o_valid[i])
      );
    end
  endgenerate

endmodule
