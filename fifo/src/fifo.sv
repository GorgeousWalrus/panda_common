// ------------------------ Disclaimer -----------------------
// No warranty of correctness, synthesizability or 
// functionality of this code is given.
// Use this code under your own risk.
// When using this code, copy this disclaimer at the top of 
// Your file
//
// (c) Luca Hanel 2020
//
// ------------------------------------------------------------
//
// Module name: fifo
// 
// Functionality: A fifo template with E/F/AE/AF signals
//
// ------------------------------------------------------------

module fifo#(
  parameter WIDTH = 32,
  parameter DEPTH = 8,
  parameter ALMOST_EN = 1,
  parameter ALMOST_THR = DEPTH-1
)(
  input logic                   clk_i,
  input logic                   rstn_i,
  input logic [WIDTH-1:0]       din_i,
  input logic                   we_i, // write enable
  input logic                   re_i, // read enable
  output logic [WIDTH-1:0]      dout_o,
  output logic                  E_o,
  output logic                  F_o,
  output logic                  AE_o,
  output logic                  AF_o
);
/* verilator lint_off WIDTH */
localparam logic [$clog2(DEPTH):0] FULL = DEPTH;
localparam logic [$clog2(DEPTH):0] EMPTY = 0;
localparam logic [$clog2(DEPTH):0] ALMOST_FULL = DEPTH-ALMOST_THR;
localparam logic [$clog2(DEPTH):0] ALMOST_EMPTY = ALMOST_THR;
/* verilator lint_on WIDTH */

logic [WIDTH-1:0]             data [0:DEPTH-1];
logic [$clog2(DEPTH):0]       write_cnt;

logic empty;
logic full;
logic almost_empty;
logic almost_full;

assign E_o    = empty;
assign F_o    = full;
assign AE_o   = almost_empty;
assign AF_o   = almost_full;
assign dout_o = data[0];

// full, almost full, empty, almost empty signals
generate
  always_comb
  begin
    empty = 1'b0;
    full = 1'b0;
    almost_empty = 1'b0;
    almost_full = 1'b0;

    if(write_cnt == FULL) full = 1'b1;
    if(write_cnt == EMPTY) empty = 1'b1;
    /* verilator lint_off UNSIGNED */
    /* verilator lint_off CMPCONST */
    if(ALMOST_EN == 1) begin // only assert almost signals if almost_en is set
      if(write_cnt >= ALMOST_FULL) almost_full = 1'b1;
      if(write_cnt <= ALMOST_EMPTY) almost_empty = 1'b1;
    end
    /* verilator lint_on CMPCONST */
    /* verilator lint_on UNSIGNED */
  end
endgenerate

always_ff @(posedge clk_i, negedge rstn_i)
begin
  if(!rstn_i) begin
    write_cnt <= 'b0;
  end else begin
    // Read and write
    if(!full && we_i && !empty && re_i) begin
      // We read and write at the same time, dont increase write counter
      for(int i = 0; i < DEPTH-1; i = i + 1)
        data[i] <= data[i+1];
      data[write_cnt[2:0]-1] <= din_i;
    end else if (!empty && re_i) begin
      // We read, decrease write counter
      for(int i = 0; i < DEPTH-1; i = i + 1)
        data[i] <= data[i+1];
      write_cnt <= write_cnt-1;
    end else if(!full && we_i) begin
      // We write, increase write counter
      data[write_cnt[$clog2(DEPTH)-1:0]] <= din_i;
      write_cnt <= write_cnt+1;      
    end
  end
end

endmodule