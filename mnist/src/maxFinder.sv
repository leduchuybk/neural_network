module maxFinder #(
  parameter integer numInput   = 10,
  parameter integer inputWidth = 16)
(
  input  logic                               i_clk ,
  input  logic                               i_rstn,
  input  logic [(numInput*inputWidth)-1:0]   i_data,
  input  logic                               i_valid,
  output logic [31:0]                        o_data,
  output logic                               o_data_valid
);

  logic [inputWidth-1:0] maxValue;
  logic [(numInput*inputWidth)-1:0] inDataBuffer;
  integer counter;

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      counter <= 0;
      o_data_valid <= 1'b0;
      o_data <= 'd0;
      maxValue <= 'd0;
      inDataBuffer <= 'd0;
    end else begin
      o_data_valid <= 1'b0;
      if(i_valid) begin
        maxValue <= i_data[inputWidth-1:0];
        counter <= 1;
        inDataBuffer <= i_data;
        o_data <= 0;
      end else if(counter == numInput) begin
        counter <= 0;
        o_data_valid <= 1'b1;
      end else if(counter != 0) begin
        counter <= counter + 1;
        if(inDataBuffer[counter*inputWidth+:inputWidth] > maxValue) begin
          maxValue <= inDataBuffer[counter*inputWidth+:inputWidth];
          o_data <= counter;
        end
      end
    end
  end

endmodule
