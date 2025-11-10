// ============================================================================
// File:    fifo_uvm_tb_top.sv
// Author:  MiniMax Agent
// Purpose: Top-level testbench for dual-clock FIFO UVM verification
// ============================================================================

`ifndef FIFO_UVM_TB_TOP_SV
`define FIFO_UVM_TB_TOP_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "fifo_uvm_env_config.sv"
`include "write_agent_config.sv"
`include "read_agent_config.sv"
`include "fifo_uvm_transaction.sv"
`include "fifo_uvm_env.sv"
`include "write_sequencer.sv"
`include "write_driver.sv"
`include "write_monitor.sv"
`include "write_agent.sv"
`include "read_sequencer.sv"
`include "read_driver.sv"
`include "read_monitor.sv"
`include "read_agent.sv"
`include "fifo_scoreboard.sv"
`include "fifo_coverage.sv"
`include "fifo_uvm_base_test.sv"
`include "fifo_uvm_tests.sv"
`include "fifo_sequences.sv"

// Include original RTL modules
`include "user_input_files/fifo1.v"
`include "user_input_files/fifomem.v"
`include "user_input_files/wptr_full.v"
`include "user_input_files/rptr_empty.v"
`include "user_input_files/sync_w2r.v"
`include "user_input_files/sync_r2w.v"

// Top-level testbench module
module fifo_uvm_tb_top;
  
  // Import package
  import uvm_pkg::*;
  
  // Virtual interface
  virtual fifo_if vif;
  
  // DUT instance
  fifo1 #(
    .DSIZE(8),
    .ASIZE(4)
  ) dut (
    .wdata(vif.wdata),
    .wfull(vif.wfull),
    .winc(vif.winc),
    .wclk(vif.wclk),
    .wrst_n(vif.wrst_n),
    .rdata(vif.rdata),
    .rempty(vif.rempty),
    .rinc(vif.rinc),
    .rclk(vif.rclk),
    .rrst_n(vif.rrst_n)
  );
  
  // Initial block for test execution
  initial begin
    // Create virtual interface
    vif = new();
    
    // Connect virtual interface to testbench components
    uvm_config_db#(virtual fifo_if)::set(null, "uvm_test_top", "vif", vif);
    uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", vif);
    
    // Start clock generation
    fork
      begin
        vif.generate_wclk(100); // 100 MHz write clock
      end
      begin
        vif.generate_rclk(75);  // 75 MHz read clock
      end
    join
    
  end
  
  // Initial block for test execution
  initial begin
    // Wait for clocks to stabilize
    #10ns;
    
    // Run test
    run_test("fifo_normal_test");
  end
  
  // VCD dump for waveform analysis
  initial begin
    $dumpfile("fifo_uvm_simulation.vcd");
    $dumpvars(0, fifo_uvm_tb_top);
  end
  
endmodule

// Clock generation module for cleaner separation
module clock_generator;
  
  parameter WCLK_FREQ = 100; // MHz
  parameter RCLK_FREQ = 75;  // MHz
  
  // Generate write clock
  initial begin
    time half_period = (1000 / WCLK_FREQ) / 2 * 1ns;
    forever begin
      wclk <= 0;
      #half_period;
      wclk <= 1;
      #half_period;
    end
  end
  
  // Generate read clock
  initial begin
    time half_period = (1000 / RCLK_FREQ) / 2 * 1ns;
    forever begin
      rclk <= 0;
      #half_period;
      rclk <= 1;
      #half_period;
    end
  end
  
endmodule

// Test configuration module
module test_config;
  
  // Test selection via command line
  string test_name = "fifo_normal_test";
  int wclk_freq_mhz = 100;
  int rclk_freq_mhz = 75;
  int num_transactions = 1000;
  
  initial begin
    // Parse command line arguments
    if ($value$plusargs("TESTNAME=%s", test_name)) begin
      `uvm_info("CONFIG", $sformatf("Test name: %s", test_name), UVM_LOW)
    end
    
    if ($value$plusargs("WCLK_FREQ=%d", wclk_freq_mhz)) begin
      `uvm_info("CONFIG", $sformatf("Write clock frequency: %0d MHz", wclk_freq_mhz), UVM_LOW)
    end
    
    if ($value$plusargs("RCLK_FREQ=%d", rclk_freq_mhz)) begin
      `uvm_info("CONFIG", $sformatf("Read clock frequency: %0d MHz", rclk_freq_mhz), UVM_LOW)
    end
    
    if ($value$plusargs("NUM_TRANSACTIONS=%d", num_transactions)) begin
      `uvm_info("CONFIG", $sformatf("Number of transactions: %0d", num_transactions), UVM_LOW)
    end
  end
  
endmodule

// Coverage reporting module
module coverage_reporter;
  
  real write_coverage;
  real read_coverage;
  real cross_coverage;
  real overall_coverage;
  
  initial begin
    // This would be populated by actual coverage data
    // For now, this is a placeholder for post-simulation analysis
  end
  
endmodule

`endif // FIFO_UVM_TB_TOP_SV