`include "layer_parameter.sv"

module dnn # (
  parameter integer C_S_AXI_DATA_WIDTH = 32,
  parameter integer C_S_AXI_ADDR_WIDTH = 32
)
(
  //Clock and Reset
  input  logic                                s_axi_aclk,
  input  logic                                s_axi_aresetn,
  //AXI Stream interface for Input
  input  logic [`dataWidth-1:0]               axis_in_data,
  input  logic                                axis_in_data_valid,
  output logic                                axis_in_data_ready,
  //AXI Lite Interface for Configuration
  input  logic [C_S_AXI_ADDR_WIDTH-1 : 0]     s_axi_awaddr,
  input  logic [2 : 0]                        s_axi_awprot,
  input  logic                                s_axi_awvalid,
  output logic                                s_axi_awready,
  input  logic [C_S_AXI_DATA_WIDTH-1 : 0]     s_axi_wdata,
  input  logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
  input  logic                                s_axi_wvalid,
  output logic                                s_axi_wready,
  output logic [1 : 0]                        s_axi_bresp,
  output logic                                s_axi_bvalid,
  input  logic                                s_axi_bready,
  input  logic [C_S_AXI_ADDR_WIDTH-1 : 0]     s_axi_araddr,
  input  logic [2 : 0]                        s_axi_arprot,
  input  logic                                s_axi_arvalid,
  output logic                                s_axi_arready,
  output logic [C_S_AXI_DATA_WIDTH-1 : 0]     s_axi_rdata,
  output logic [1 : 0]                        s_axi_rresp,
  output logic                                s_axi_rvalid,
  input  logic                                s_axi_rready,
  //Interrupt interface
  output logic                                intr
);
  localparam logic IDLE = 1'b0;
  localparam logic SEND = 1'b1;

  logic        softReset;
  logic  rstn;

  logic [31:0] config_layer_num;
  logic [31:0] config_neuron_num;
  logic [31:0] weightValue;
  logic [31:0] biasValue;
  logic [31:0] out;
  logic out_valid;
  logic weightValid;
  logic biasValid;
  logic axi_rd_en;
  logic [31:0] axi_rd_data;

  logic [`numNeuronLayer1-1:0]            o1_valid;
  logic [`numNeuronLayer1*`dataWidth-1:0] x1_out;
  logic [`dataWidth-1:0] out_data_1;
  logic data_out_valid_1;

  logic [`numNeuronLayer2-1:0]            o2_valid;
  logic [`numNeuronLayer2*`dataWidth-1:0] x2_out;
  logic [`dataWidth-1:0] out_data_2;
  logic data_out_valid_2;

  logic [`numNeuronLayer3-1:0]            o3_valid;
  logic [`numNeuronLayer3*`dataWidth-1:0] x3_out;
  logic [`dataWidth-1:0] out_data_3;
  logic data_out_valid_3;

  logic [`numNeuronLayer4-1:0]            o4_valid;
  logic [`numNeuronLayer4*`dataWidth-1:0] x4_out;
  logic [`dataWidth-1:0] out_data_4;
  logic data_out_valid_4;

  logic [`numNeuronLayer4*`dataWidth-1:0] holdData;

  assign rstn = s_axi_aresetn & !softReset;
  assign intr = out_valid;

  axi_lite_wrapper # (
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
  ) u_alw (
    .S_AXI_ACLK        (s_axi_aclk),
    .S_AXI_ARESETN     (s_axi_aresetn),
    .S_AXI_AWADDR      (s_axi_awaddr),
    .S_AXI_AWPROT      (s_axi_awprot),
    .S_AXI_AWVALID     (s_axi_awvalid),
    .S_AXI_AWREADY     (s_axi_awready),
    .S_AXI_WDATA       (s_axi_wdata),
    .S_AXI_WSTRB       (s_axi_wstrb),
    .S_AXI_WVALID      (s_axi_wvalid),
    .S_AXI_WREADY      (s_axi_wready),
    .S_AXI_BRESP       (s_axi_bresp),
    .S_AXI_BVALID      (s_axi_bvalid),
    .S_AXI_BREADY      (s_axi_bready),
    .S_AXI_ARADDR      (s_axi_araddr),
    .S_AXI_ARPROT      (s_axi_arprot),
    .S_AXI_ARVALID     (s_axi_arvalid),
    .S_AXI_ARREADY     (s_axi_arready),
    .S_AXI_RDATA       (s_axi_rdata),
    .S_AXI_RRESP       (s_axi_rresp),
    .S_AXI_RVALID      (s_axi_rvalid),
    .S_AXI_RREADY      (s_axi_rready),
    .layerNumber       (config_layer_num),
    .neuronNumber      (config_neuron_num),
    .weightValue       (weightValue),
    .weightValid       (weightValid),
    .biasValid         (biasValid),
    .biasValue         (biasValue),
    .nnOut_valid       (out_valid),
    .nnOut             (out),
    .axi_rd_en         (axi_rd_en),
    .axi_rd_data       (axi_rd_data),
    .softReset         (softReset)
  );

  assign axis_in_data_ready = 1'b1;
  Layer1 #(
    .NN(`numNeuronLayer1),
    .numWeight(`numWeightLayer1),
    .dataWidth(`dataWidth),
    .layerNum(1),
    .sigmoidSize(`sigmoidSize),
    .weightIntWidth(`weightIntWidth),
    .actType(`Layer1ActType))
  u_Layer1(
    .clk(s_axi_aclk),
    .rstn(rstn),
    .weightValid(weightValid),
    .biasValid(biasValid),
    .weightValue(weightValue),
    .biasValue(biasValue),
    .config_layer_num(config_layer_num),
    .config_neuron_num(config_neuron_num),
    .x_valid(axis_in_data_valid),
    .x_in(axis_in_data),
    .o_valid(o1_valid),
    .x_out(x1_out)
  );

  serialize #(
    .dataWidth(`dataWidth),
    .numNeuron(`numNeuronLayer1)
  ) u_serialize1(
    .clk(s_axi_aclk),
    .rstn(rstn),
    .parallel_valid(o1_valid[0]),
    .parallel_data(x1_out),
    .serialize_valid(data_out_valid_1),
    .serialize_data(out_data_1)
  );

  Layer2 #(
    .NN(`numNeuronLayer2),
    .numWeight(`numWeightLayer2),
    .dataWidth(`dataWidth),
    .layerNum(2),
    .sigmoidSize(`sigmoidSize),
    .weightIntWidth(`weightIntWidth),
    .actType(`Layer2ActType))
  u_Layer2(
    .clk(s_axi_aclk),
    .rstn(rstn),
    .weightValid(weightValid),
    .biasValid(biasValid),
    .weightValue(weightValue),
    .biasValue(biasValue),
    .config_layer_num(config_layer_num),
    .config_neuron_num(config_neuron_num),
    .x_valid(data_out_valid_1),
    .x_in(out_data_1),
    .o_valid(o2_valid),
    .x_out(x2_out)
  );

  serialize #(
    .dataWidth(`dataWidth),
    .numNeuron(`numNeuronLayer2)
  ) u_serialize2(
    .clk(s_axi_aclk),
    .rstn(rstn),
    .parallel_valid(o2_valid[0]),
    .parallel_data(x2_out),
    .serialize_valid(data_out_valid_2),
    .serialize_data(out_data_2)
  );

  Layer3 #(
    .NN(`numNeuronLayer3),
    .numWeight(`numWeightLayer3),
    .dataWidth(`dataWidth),
    .layerNum(3),
    .sigmoidSize(`sigmoidSize),
    .weightIntWidth(`weightIntWidth),
    .actType(`Layer3ActType))
  u_Layer3 (
    .clk(s_axi_aclk),
    .rstn(rstn),
    .weightValid(weightValid),
    .biasValid(biasValid),
    .weightValue(weightValue),
    .biasValue(biasValue),
    .config_layer_num(config_layer_num),
    .config_neuron_num(config_neuron_num),
    .x_valid(data_out_valid_2),
    .x_in(out_data_2),
    .o_valid(o3_valid),
    .x_out(x3_out)
  );

  serialize #(
    .dataWidth(`dataWidth),
    .numNeuron(`numNeuronLayer3)
  ) u_serialize3(
    .clk(s_axi_aclk),
    .rstn(rstn),
    .parallel_valid(o3_valid[0]),
    .parallel_data(x3_out),
    .serialize_valid(data_out_valid_3),
    .serialize_data(out_data_3)
  );

  Layer4 #(
    .NN(`numNeuronLayer4),
    .numWeight(`numWeightLayer4),
    .dataWidth(`dataWidth),
    .layerNum(4),
    .sigmoidSize(`sigmoidSize),
    .weightIntWidth(`weightIntWidth),
    .actType(`Layer4ActType))
  u_Layer4 (
    .clk(s_axi_aclk),
    .rstn(rstn),
    .weightValid(weightValid),
    .biasValid(biasValid),
    .weightValue(weightValue),
    .biasValue(biasValue),
    .config_layer_num(config_layer_num),
    .config_neuron_num(config_neuron_num),
    .x_valid(data_out_valid_3),
    .x_in(out_data_3),
    .o_valid(o4_valid),
    .x_out(x4_out)
  );

  maxFinder #(
    .numInput(`numNeuronLayer5),
    .inputWidth(`dataWidth))
  u_maxFinder(
    .i_clk(s_axi_aclk),
    .i_rstn(rstn),
    .i_data(x4_out),
    .i_valid(o4_valid[0]),
    .o_data(out),
    .o_data_valid(out_valid)
  );

  assign axi_rd_data = holdData[`dataWidth-1:0];
  always_ff @(posedge s_axi_aclk or negedge rstn) begin
    if (!rstn) begin
      holdData <= 'd0;
    end else begin
      if (o4_valid[0] == 1'b1)
          holdData <= x4_out;
      else if(axi_rd_en) begin
          holdData <= holdData >> `dataWidth;
      end
    end
  end
endmodule
