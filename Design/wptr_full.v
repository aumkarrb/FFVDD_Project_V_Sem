module wptr_full #(
  parameter ADDRSIZE = 4
) (
  output reg              wfull,
  output [ADDRSIZE:0]     wr_count,
  output [ADDRSIZE-1:0]   waddr,
  output reg [ADDRSIZE:0] wptr,
  input  [ADDRSIZE:0]     wrptr2,
  input                   winc,
  input                   wclk,
  input                   wrst_n
);

  reg [ADDRSIZE:0] wbin;
  wire [ADDRSIZE:0] wgnext, wbnext;
  
  // Gray to binary conversion for current wptr
  wire [ADDRSIZE:0] wbin_current;
  assign wbin_current = gray2bin(wptr);
  
  // Memory write-address pointer (use lower ADDRSIZE bits)
  assign waddr = wptr[ADDRSIZE-1:0];
  
  // Generate next binary and Gray values
  assign wbnext = wbin + (winc & ~wfull);
  assign wgnext = (wbnext >> 1) ^ wbnext;
  
  // Update pointers
  always @(posedge wclk or negedge wrst_n)
    if (!wrst_n) begin
      wbin <= 0;
      wptr <= 0;
    end else begin
      wbin <= wbnext;
      wptr <= wgnext;
    end
  
  // Full detection: MSBs differ, other bits equal
  wire wfull_val;
  assign wfull_val = (wgnext == {~wrptr2[ADDRSIZE], wrptr2[ADDRSIZE-1:0]});
  
  always @(posedge wclk or negedge wrst_n)
    if (!wrst_n)
      wfull <= 1'b0;
    else
      wfull <= wfull_val;
  
  // Write count calculation
  wire [ADDRSIZE:0] wrptr2_bin;
  assign wrptr2_bin = gray2bin(wrptr2);
  assign wr_count = wbin_current - wrptr2_bin;
  
  // Gray to Binary conversion function
  function [ADDRSIZE:0] gray2bin;
    input [ADDRSIZE:0] gray;
    integer i;
    begin
      gray2bin[ADDRSIZE] = gray[ADDRSIZE];
      for (i = ADDRSIZE-1; i >= 0; i = i - 1)
        gray2bin[i] = gray2bin[i+1] ^ gray[i];
    end
  endfunction
  
endmodule