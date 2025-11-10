module rptr_empty #(
  parameter ADDRSIZE = 4
) (
  output reg              rempty,
  output [ADDRSIZE:0]     rd_count,
  output [ADDRSIZE-1:0]   raddr,
  output reg [ADDRSIZE:0] rptr,
  input  [ADDRSIZE:0]     rwptr2,
  input                   rinc,
  input                   rclk,
  input                   rrst_n
);

  reg [ADDRSIZE:0] rbin;
  wire [ADDRSIZE:0] rgnext, rbnext;
  
  // Gray to binary conversion for current rptr
  wire [ADDRSIZE:0] rbin_current;
  assign rbin_current = gray2bin(rptr);
  
  // Memory read-address pointer (use lower ADDRSIZE bits)
  assign raddr = rptr[ADDRSIZE-1:0];
  
  // Generate next binary and Gray values
  assign rbnext = rbin + (rinc & ~rempty);
  assign rgnext = (rbnext >> 1) ^ rbnext;
  
  // Update pointers
  always @(posedge rclk or negedge rrst_n)
    if (!rrst_n) begin
      rbin <= 0;
      rptr <= 0;
    end else begin
      rbin <= rbnext;
      rptr <= rgnext;
    end
  
  // Empty detection: rgnext == synchronized wptr
  wire rempty_val;
  assign rempty_val = (rgnext == rwptr2);
  
  always @(posedge rclk or negedge rrst_n)
    if (!rrst_n)
      rempty <= 1'b1;
    else
      rempty <= rempty_val;
  
  // Read count calculation
  wire [ADDRSIZE:0] rwptr2_bin;
  assign rwptr2_bin = gray2bin(rwptr2);
  assign rd_count = rwptr2_bin - rbin_current;
  
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