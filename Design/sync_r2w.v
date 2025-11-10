module sync_r2w #(
  parameter ADDRSIZE = 4
) (
  output reg [ADDRSIZE:0] wrptr2,
  input  [ADDRSIZE:0] rptr,
  input               wclk,
  input               wrst_n
);

  reg [ADDRSIZE:0] wrptr1;
  
  always @(posedge wclk or negedge wrst_n)
    if (!wrst_n)
      {wrptr2, wrptr1} <= 0;
    else
      {wrptr2, wrptr1} <= {wrptr1, rptr};
      
endmodule