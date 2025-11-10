`timescale 1ns / 1ps
`include "layer_parameter.sv"

module tb_dnn();
  logic resetn = 1'b0;
  logic clock = 1'b0;
  logic [`dataWidth-1:0] in;
  logic in_valid;
  logic [`dataWidth-1:0] in_mem [785];
  string fileName;
  logic s_axi_awvalid = 1'b0;
  logic [31:0] s_axi_awaddr;
  logic s_axi_awready;
  logic [31:0] s_axi_wdata;
  logic s_axi_wvalid = 1'b0;
  logic s_axi_wready;
  logic s_axi_bvalid;
  logic s_axi_bready = 1'b0;
  logic intr;
  logic [31:0] axiRdData;
  logic [31:0] s_axi_araddr;
  logic [31:0] s_axi_rdata;
  logic s_axi_arvalid = 1'b0;
  logic s_axi_arready;
  logic s_axi_rvalid;
  logic s_axi_rready;
  logic [`dataWidth-1:0] expected;

  logic [31:0] numNeurons[1:31];
  logic [31:0] numWeights[1:31];

  assign numNeurons[1] = 30;
  assign numNeurons[2] = 30;
  assign numNeurons[3] = 10;
  assign numNeurons[4] = 10;

  assign numWeights[1] = 784;
  assign numWeights[2] = 30;
  assign numWeights[3] = 30;
  assign numWeights[4] = 10;

  integer right=0;
  integer wrong=0;

  integer i,j,layerNo=1,k;
  integer start;
  integer testDataCount;
  integer testDataCount_int;

  `include "ultilities.sv"

  dnn #(
    .C_S_AXI_DATA_WIDTH(32),
    .C_S_AXI_ADDR_WIDTH(32)
  ) dut(
    .s_axi_aclk(clock),
    .s_axi_aresetn(resetn),
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
    .axis_in_data(in),
    .axis_in_data_valid(in_valid),
    .axis_in_data_ready(),
    .intr(intr)
  );

  always @(posedge clock) begin
    s_axi_bready <= s_axi_bvalid;
    s_axi_rready <= s_axi_rvalid;
  end
  always #5 clock = ~clock;
  initial begin
      resetn = 1'b0;
      in_valid = 0;
      #100;
      resetn = 1'b1;
      #100
      writeAxi(28,0);//clear soft reset
      start = $time;
`ifndef PRETRAINED
      configWeights();
      configBias();
`endif
      $display("Configuration completed",,,,$time-start,,"ns");
      start = $time;
      for(testDataCount=0;testDataCount<`MAXTESTSAMPLES;testDataCount=testDataCount+1)
      begin
        fileName = $sformatf("%stest_data_%04d.txt",`TEST_DIR,(testDataCount));
        sendData();
        @(posedge intr);
        //readAxi(24);
        //$display("Status: %0x",axiRdData);
        readAxi(8);
        if(axiRdData==expected)
            right = right+1;
        $display("%0d. Accuracy: %f, Detected number: %0x, Expected: %x",testDataCount,
          right*100.0/(testDataCount+1),axiRdData,expected);
        $display("Test data %d: %s",testDataCount,fileName);
        /*$display("Total execution time",,,,$time-start,,"ns");
        j=0;
        repeat(10)
        begin
            readAxi(20);
            $display("Output of Neuron %d: %0x",j,axiRdData);
            j=j+1;
        end*/
      end
      $display("Accuracy: %f %%",right*100.0/testDataCount);
      $finish();
  end

endmodule
