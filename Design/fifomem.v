module fifomem #(
  parameter DATASIZE = 8,
  parameter ADDRSIZE = 4
) (
  output [DATASIZE-1:0] rdata,
  input  [DATASIZE-1:0] wdata,
  input  [ADDRSIZE-1:0] waddr,
  input  [ADDRSIZE-1:0] raddr,
  input                 wclken,
  input                 wclk
);

  // Memory array - depth = 2^ADDRSIZE
  reg [DATASIZE-1:0] MEM [0:(1<<ADDRSIZE)-1];
  
  assign rdata = MEM[raddr];
  
  always @(posedge wclk)
    if (wclken)
      MEM[waddr] <= wdata;
      
endmodule