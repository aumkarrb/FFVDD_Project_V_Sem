// ============================================================================
// File:    fifo_if.sv
// Author:  MiniMax Agent
// Purpose: Virtual interface for FIFO DUT signals and clocks
// ============================================================================

`ifndef FIFO_IF_SV
`define FIFO_IF_SV

interface fifo_if;
  // Write domain signals
  bit wclk;
  bit wrst_n;
  bit [7:0] wdata;
  bit winc;
  bit wfull;
  bit [4:0] wr_count;
  
  // Read domain signals
  bit rclk;
  bit rrst_n;
  bit [7:0] rdata;
  bit rinc;
  bit rempty;
  bit [4:0] rd_count;
  
  // Clock generation tasks
  task generate_wclk(int freq_mhz = 100);
    time half_period = (1000 / freq_mhz) / 2 * 1ns;
    forever begin
      wclk <= 0;
      #half_period;
      wclk <= 1;
      #half_period;
    end
  endtask
  
  task generate_rclk(int freq_mhz = 100);
    time half_period = (1000 / freq_mhz) / 2 * 1ns;
    forever begin
      rclk <= 0;
      #half_period;
      rclk <= 1;
      #half_period;
    end
  endtask
  
  // Reset generation tasks
  task generate_wrst(bit async = 1);
    wrst_n <= 0;
    if (async) begin
      @(posedge wclk);
    end
    repeat (5) @(posedge wclk);
    wrst_n <= 1;
  endtask
  
  task generate_rrst(bit async = 1);
    rrst_n <= 0;
    if (async) begin
      @(posedge rclk);
    end
    repeat (5) @(posedge rclk);
    rrst_n <= 1;
  endtask
  
  // Modport for DUT connection
  modport dut_modport (
    output wdata, winc, wfull, wr_count,
    output rdata, rinc, rempty, rd_count,
    input wclk, wrst_n, rclk, rrst_n
  );
  
  // Modport for testbench connection
  modport tb_modport (
    input wdata, winc, wfull, wr_count,
    input rdata, rinc, rempty, rd_count,
    output wclk, wrst_n, rclk, rrst_n
  );
  
endinterface

`endif // FIFO_IF_SV