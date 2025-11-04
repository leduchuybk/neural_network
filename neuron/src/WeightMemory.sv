module WeightMemory #(
  parameter int    numWeight    =  3,
  parameter int    neuronNo     =  5,
  parameter int    layerNo      =  1,
  parameter int    addressWidth = 10,
  parameter int    dataWidth    = 16,
  parameter string weightFile   = "w_1_15.mif")
(
    input clk,
    input wr_en,
    input rd_en,
    input [addressWidth-1:0] wr_addr,
    input [addressWidth-1:0] rd_addr,
    input [dataWidth-1:0] wr_data,
    output reg [dataWidth-1:0] rd_data
);

    reg [dataWidth-1:0] mem [numWeight];

`ifdef PRETRAINED
  initial
  begin
    $readmemb(weightFile, mem);
  end
`else
  always @(posedge clk)
  begin
    if (wr_en) begin
      mem[wr_addr] <= wr_data;
    end
  end
`endif

  always @(posedge clk)
  begin
      if (rd_en)
      begin
          rd_data <= mem[rd_addr];
      end
  end
endmodule
