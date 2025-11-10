module serialize #(
  parameter int dataWidth = 16,
  parameter int numNeuron = 30
)(
  input  logic                           clk,
  input  logic                           rstn,
  input  logic                           parallel_valid,
  input  logic [numNeuron*dataWidth-1:0] parallel_data,
  output logic                           serialize_valid,
  output logic [dataWidth-1:0]           serialize_data
);
  localparam logic IDLE = 1'b0;
  localparam logic SEND = 1'b1;
  logic state;
  int cnt;
  logic [numNeuron*dataWidth-1:0] tmp;

  always_ff @( posedge clk or negedge rstn ) begin : FSM
    if(!rstn) begin
      state <= IDLE;
      cnt   <= 0;
      serialize_valid <= 1'b0;
      serialize_data <= 0;
      tmp <= 'd0;
    end else begin
      case(state)
        IDLE: begin
          cnt <= 0;
          serialize_valid <= 1'b0;
          serialize_data <= 0;
          if (parallel_valid) begin
            state <= SEND;
            tmp <= parallel_data;
          end
        end
        SEND: begin
          serialize_valid <= 1'b1;
          serialize_data  <= tmp[dataWidth-1:0];
          tmp <= tmp >> dataWidth;
          cnt <= cnt + 1;
          if (cnt == numNeuron) begin
            state <= IDLE;
            serialize_valid <= 1'b0;
          end
        end
        default: begin
          state <= IDLE;
          cnt   <= 0;
          serialize_valid <= 1'b0;
          serialize_data <= 0;
          tmp <= 'd0;
        end
      endcase
    end
  end

endmodule
