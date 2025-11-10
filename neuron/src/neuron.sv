module neuron
#(
  parameter int    layerNo=0,
  parameter int    neuronNo=0,
  parameter int    numWeight=784,
  parameter int    dataWidth=16,
  parameter int    sigmoidSize=5,
  parameter int    weightIntWidth=1,
  parameter string actType="relu",
  parameter string biasFile="",
  parameter string weightFile="",
  parameter string sigFile=""
)
(
  input  logic                 clk,
  input  logic                 rstn,
  input  logic [dataWidth-1:0] mInput,
  input  logic                 mInputValid,
  input  logic [31:0]          mWeight,
  input  logic                 mWeightValid,
  input  logic [31:0]          mBias,
  input  logic                 mBiasValid,
  input  logic [31:0]          config_layer_num,
  input  logic [31:0]          config_neuron_num,
  output logic [dataWidth-1:0] mOutput,
  output logic                 mOutputValid
);

  logic [$clog2(numWeight)-1:0] rcnt;
  logic [$clog2(numWeight)-1:0] wcnt;
  logic [dataWidth-1:0] w_in;
  logic                 wr_en;
  logic [dataWidth-1:0] w_out;
  logic [dataWidth-1:0] mInput_dl;
  logic [2*dataWidth-1:0] mul;
  logic [2*dataWidth-1:0] comboAdd;
  logic [2*dataWidth:0] comboAdd_nxt;
  logic [2*dataWidth-1:0] sum;
  logic [2*dataWidth:0] sum_nxt;
  logic [2*dataWidth-1:0] bias;
  logic [31:0] biasReg [1];
  logic enb0, enb1, enb2;
  logic enb2_dl;
  logic last_weight, last_mul;

  always_ff @( posedge clk or negedge rstn ) begin : RD_Counter
    if (!rstn) begin
      rcnt <= 'd0;
    end else begin
      if (mInputValid) begin
        if (rcnt == numWeight-1) rcnt <= 32'd0;
        else                     rcnt <= rcnt + 1;
      end else begin
        rcnt <= rcnt;
      end
    end
  end

  always_ff @( posedge clk or negedge rstn ) begin : WR_Counter
    if (!rstn) begin
      wcnt <= 'd0;
    end else begin
      if (mWeightValid) begin
        if (wcnt == numWeight-1) wcnt <= 32'd0;
        else wcnt <= wcnt + 1;
      end else begin
        wcnt <= wcnt;
      end
    end
  end
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      w_in  <= {dataWidth{1'b0}};
      wr_en <= 1'b0;
    end else begin
      if ((mWeightValid) & (config_layer_num==layerNo) & (config_neuron_num==neuronNo)) begin
        w_in <= mWeight[dataWidth-1:0];
        wr_en <= 1'b1;
      end else begin
        wr_en <= 1'b0;
      end
    end
  end
  WeightMemory #(
    .numWeight(numWeight),
    .addressWidth($clog2(numWeight)),
    .dataWidth(dataWidth),
    .weightFile(weightFile)
  ) u_WeightMemory (
    .clk    (clk         ),
    .wr_data(w_in        ),
    .wr_en  (wr_en       ),
    .wr_addr(wcnt        ),
    .rd_data(w_out       ),
    .rd_en  (mInputValid ),
    .rd_addr(rcnt        )
  );

  always_ff@( posedge clk or negedge rstn) begin : input_delay
    if (!rstn) begin
      mInput_dl <= 'd0;
    end else begin
      mInput_dl <= mInput;
    end
  end

  always_ff@( posedge clk or negedge rstn) begin : multiplier
    if (!rstn) begin
      mul <= 'd0;
    end else begin
      if (enb0) mul <= $signed(w_out) * $signed(mInput_dl);
      else mul <= mul;
    end
  end

  assign comboAdd_nxt = comboAdd + mul;
  always_ff@( posedge clk or negedge rstn) begin : sum_combo
    if (!rstn) begin
      comboAdd <= 'd0;
    end else begin
      if (enb1) begin
        // Addition of two positive but result is negative => overflow
        if (!comboAdd[2*dataWidth-1] & !mul[2*dataWidth-1]
            & comboAdd_nxt[2*dataWidth-1]) begin
          comboAdd[2*dataWidth-1]   <= 1'b0;
          comboAdd[2*dataWidth-2:0] <= {2*dataWidth-1{1'b1}};
        // Addition of two negative but result is positive => overflow
        end else if (comboAdd[2*dataWidth-1] & mul[2*dataWidth-1]
                    & !comboAdd_nxt[2*dataWidth-1]) begin
          comboAdd[2*dataWidth-1]   <= 1'b1;
          comboAdd[2*dataWidth-2:0] <= {2*dataWidth-1{1'b0}};
        end
        else begin
          comboAdd <= comboAdd_nxt[2*dataWidth-1:0];
        end
      end else if (mOutputValid) begin
        comboAdd <= 'd0;
      end else begin
        comboAdd <= comboAdd;
      end
    end
  end

  assign sum_nxt = (enb2) ? comboAdd + bias : 'd0;
  always_ff@( posedge clk or negedge rstn) begin : sum_result
    if (!rstn) begin
      sum <= 'd0;
    end else begin
      if (enb2) begin
        // Addition of two positive but result is negative => overflow
        if (!comboAdd[2*dataWidth-1] & !bias[2*dataWidth-1] & sum_nxt[2*dataWidth-1]) begin
          sum[2*dataWidth-1]   <= 1'b0;
          sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b1}};
        // Addition of two negative but result is positive => overflow
        end else if (comboAdd[2*dataWidth-1] & bias[2*dataWidth-1] & !sum_nxt[2*dataWidth-1]) begin
          sum[2*dataWidth-1]   <= 1'b1;
          sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b0}};
        end else begin
          sum <= sum_nxt[2*dataWidth-1:0];
        end
      end else if (mOutputValid) begin
        sum <= 'd0;
      end else begin
        sum <= sum;
      end
    end
  end

  generate
    if(actType == "sigmoid") begin: g_siginst
    //Instantiation of ROM for sigmoid
      Sig_ROM #(
        .inWidth(sigmoidSize),
        .dataWidth(dataWidth),
        .sigContent(sigFile)
      ) u_Sig_ROM (
      .clk(clk),
      .x(sum[2*dataWidth-1-:sigmoidSize]),
      .out(mOutput)
    );
    end else begin: g_ReLUinst
      ReLU #(
        .dataWidth(dataWidth),
        .weightIntWidth(weightIntWidth)
      ) u_ReLU (
      .clk(clk),
      .x(sum),
      .out(mOutput)
    );
    end
  endgenerate

`ifdef PRETRAINED
  initial
  begin
      $readmemb(biasFile,biasReg);
  end
  always @(posedge clk)
  begin
      bias <= {biasReg[0][dataWidth-1:0],{dataWidth{1'b0}}};
  end
`else
  always @(posedge clk)
  begin
      if(mBiasValid & (config_layer_num==layerNo) & (config_neuron_num==neuronNo))
      begin
          bias <= {mBias[dataWidth-1:0],{dataWidth{1'b0}}};
      end
  end
`endif

  // Controller
  always_ff @( posedge clk or negedge rstn) begin: Controller
    if (!rstn) begin
      enb0 <= 1'b0;
      enb1 <= 1'b0;
      enb2 <= 1'b0;
      enb2_dl <= 1'b0;
      last_weight <= 1'b0;
      last_mul <= 1'b0;
      mOutputValid <= 1'b0;
    end else begin
      enb0 <= mInputValid;
      enb1 <= enb0;
      if (rcnt == numWeight-1) last_weight <= 1'b1;
      else last_weight <= 0;
      last_mul <= last_weight;
      enb2 <= last_mul;
      enb2_dl <= enb2;
      mOutputValid <= enb2_dl;
    end
  end
endmodule
