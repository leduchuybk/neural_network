task writeAxi(
  input [31:0] address,
  input [31:0] data
);
begin
    @(posedge clock);
    s_axi_awvalid <= 1'b1;
    s_axi_awaddr <= address;
    s_axi_wdata <= data;
    s_axi_wvalid <= 1'b1;
    wait(s_axi_wready);
    @(posedge clock);
    s_axi_awvalid <= 1'b0;
    s_axi_wvalid <= 1'b0;
    @(posedge clock);
end
endtask

task readAxi( input [31:0] address);
  begin
      @(posedge clock);
      s_axi_arvalid <= 1'b1;
      s_axi_araddr <= address;
      wait(s_axi_arready);
      @(posedge clock);
      s_axi_arvalid <= 1'b0;
      wait(s_axi_rvalid);
      @(posedge clock);
      axiRdData <= s_axi_rdata;
      @(posedge clock);
  end
endtask

task configWeights();
  integer i,j,k,t;
  integer neuronNo_int;
  logic [`dataWidth:0] config_mem [783:0];
  begin
    @(posedge clock);
    for(k=1;k<=`numLayers;k=k+1)
    begin
        writeAxi(12,k);//Write layer number
        for(j=0;j<numNeurons[k];j=j+1)
        begin
            fileName = $sformatf("%sw_%0d_%0d.mif",`WB_DIR,k,j);
            $readmemb(fileName, config_mem);
            writeAxi(16,j);//Write neuron number
            for (t=0; t<numWeights[k]; t=t+1) begin
                writeAxi(0,{15'd0,config_mem[t]});
            end
        end
    end
  end
endtask

task configBias();
integer i,j,k,t;
integer neuronNo_int;
logic [31:0] bias[0:0];
  begin
    @(posedge clock);
    for(k=1;k<=`numLayers;k=k+1)
    begin
        writeAxi(12,k);//Write layer number
        for(j=0;j<numNeurons[k];j=j+1)
        begin
            fileName = $sformatf("%sb_%0d_%0d.mif",`WB_DIR,k,j);
            $readmemb(fileName, bias);
            writeAxi(16,j);//Write neuron number
            writeAxi(4,{15'd0,bias[0]});
        end
    end
  end
endtask

task sendData();
  //input [25*7:0] fileName;
  integer t;
  begin
    $readmemb(fileName, in_mem);
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    for (t=0; t <784; t=t+1) begin
        @(posedge clock);
        in <= in_mem[t];
        in_valid <= 1;
        //@(posedge clock);
        //in_valid <= 0;
    end
    @(posedge clock);
    in_valid <= 0;
    expected = in_mem[t];
  end
endtask
