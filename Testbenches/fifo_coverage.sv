// ============================================================================
// File:    fifo_coverage.sv
// Author:  MiniMax Agent
// Purpose: Functional coverage model for FIFO cross-domain operations
// ============================================================================

`ifndef FIFO_COVERAGE_SV
`define FIFO_COVERAGE_SV

class fifo_coverage extends uvm_subscriber#(fifo_combined_transaction);
  `uvm_component_utils(fifo_coverage)
  
  // Coverage configuration
  fifo_uvm_env_config cfg;
  
  // Write domain coverage
  covergroup write_domain_cg @(posedge cfg.w_agent_cfg.wclk_freq_mhz);
    option.per_instance = 1;
    option.name = "write_domain_cg";
    
    // Write data patterns
    wdata_c: coverpoint tx.data {
      bins zero = {0};
      bins max = {8'hFF};
      bins low = {[8'h01:8'h1F]};
      bins mid = {[8'h20:8'hDF]};
      bins high = {[8'hE0:8'hFE]};
    }
    
    // Write enable patterns
    winc_c: coverpoint tx.valid_write {
      bins write = {1};
      bins idle = {0};
    }
    
    // FIFO state during writes
    wfull_c: coverpoint tx.valid_write {
      bins write_full = {1} iff (cfg.w_agent_cfg.wclk_freq_mhz > 0);
      bins write_not_full = {1} iff (cfg.w_agent_cfg.wclk_freq_mhz == 0);
    }
    
    // Cross coverage: write data vs enable
    wdata_winc_cross: cross wdata_c, winc_c;
    
  endgroup
  
  // Read domain coverage
  covergroup read_domain_cg @(posedge cfg.r_agent_cfg.rclk_freq_mhz);
    option.per_instance = 1;
    option.name = "read_domain_cg";
    
    // Read data patterns
    rdata_c: coverpoint tx.data {
      bins zero = {0};
      bins max = {8'hFF};
      bins low = {[8'h01:8'h1F]};
      bins mid = {[8'h20:8'hDF]};
      bins high = {[8'hE0:8'hFE]};
    }
    
    // Read enable patterns
    rinc_c: coverpoint tx.valid_read {
      bins read = {1};
      bins idle = {0};
    }
    
    // FIFO state during reads
    rempty_c: coverpoint tx.valid_read {
      bins read_empty = {1} iff (cfg.r_agent_cfg.rclk_freq_mhz > 0);
      bins read_not_empty = {1} iff (cfg.r_agent_cfg.rclk_freq_mhz == 0);
    }
    
    // Cross coverage: read data vs enable
    rdata_rinc_cross: cross rdata_c, rinc_c;
    
  endgroup
  
  // Cross-domain interaction coverage
  covergroup cross_domain_cg;
    option.per_instance = 1;
    option.name = "cross_domain_cg";
    
    // Latency coverage
    latency_c: coverpoint tx.latency_cycles {
      bins low_latency = {[0:2]};
      bins medium_latency = {[3:10]};
      bins high_latency = {[11:20]};
      bins very_high_latency = {[21:$]};
    }
    
    // Simultaneous operations
    simultaneous_ops: coverpoint {tx.valid_write, tx.valid_read} {
      bins neither = {2'b00};
      bins write_only = {2'b10};
      bins read_only = {2'b01};
      bins both = {2'b11};
    }
    
    // Cross-domain cross coverage
    latency_simultaneous_cross: cross latency_c, simultaneous_ops;
    
  endgroup
  
  // FIFO occupancy coverage
  covergroup occupancy_cg;
    option.per_instance = 1;
    option.name = "occupancy_cg";
    
    // FIFO occupancy levels
    occupancy_c: coverpoint tx.latency_cycles {
      bins empty = {0};
      bins quarter = {[1:4]};
      bins half = {[5:8]};
      bins three_quarter = {[9:12]};
      bins full = {[$]};
    }
    
    // State transitions
    state_transitions: coverpoint tx.latency_cycles {
      bins empty_to_quarter = (0 => [1:4]);
      bins quarter_to_half = ([1:4] => [5:8]);
      bins half_to_three_quarter = ([5:8] => [9:12]);
      bins three_quarter_to_full = ([9:12] => [$]);
      bins full_to_three_quarter = ([$] => [9:12]);
      bins three_quarter_to_half = ([9:12] => [5:8]);
      bins half_to_quarter = ([5:8] => [1:4]);
      bins quarter_to_empty = ([1:4] => 0);
    }
    
  endgroup
  
  // Edge case coverage
  covergroup edge_cases_cg;
    option.per_instance = 1;
    option.name = "edge_cases_cg";
    
    // Burst operations
    burst_write_c: coverpoint tx.valid_write {
      bins single_write = (1 [*1]);
      bins burst_2 = (1 [*2]);
      bins burst_4 = (1 [*4]);
      bins burst_8 = (1 [*8]);
    }
    
    burst_read_c: coverpoint tx.valid_read {
      bins single_read = (1 [*1]);
      bins burst_2 = (1 [*2]);
      bins burst_4 = (1 [*4]);
      bins burst_8 = (1 [*8]);
    }
    
    // Alternating patterns
    alternating_c: coverpoint {tx.valid_write, tx.valid_read} {
      bins write_read_write = (2'b10, 2'b01, 2'b10);
      bins read_write_read = (2'b01, 2'b10, 2'b01);
    }
    
  endgroup
  
  // Current transaction
  fifo_combined_transaction tx;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    
    // Create covergroups
    write_domain_cg = new();
    read_domain_cg = new();
    cross_domain_cg = new();
    occupancy_cg = new();
    edge_cases_cg = new();
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration
    if (!uvm_config_db#(fifo_uvm_env_config)::get(this, "", "config", cfg)) begin
      `uvm_error("COVERAGE", "Could not get environment configuration")
    end
  endfunction
  
  virtual function void write(fifo_combined_transaction t);
    tx = t;
    
    // Sample all covergroups
    write_domain_cg.sample();
    read_domain_cg.sample();
    cross_domain_cg.sample();
    occupancy_cg.sample();
    edge_cases_cg.sample();
    
  endfunction
  
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info("COVERAGE_REPORT", "=== Functional Coverage Results ===", UVM_LOW)
    
    // Get coverage from all covergroups
    real write_cov = write_domain_cg.get_coverage();
    real read_cov = read_domain_cg.get_coverage();
    real cross_cov = cross_domain_cg.get_coverage();
    real occ_cov = occupancy_cg.get_coverage();
    real edge_cov = edge_cases_cg.get_coverage();
    
    `uvm_info("COVERAGE_REPORT", $sformatf("Write domain coverage: %0.2f%%", write_cov), UVM_LOW)
    `uvm_info("COVERAGE_REPORT", $sformatf("Read domain coverage: %0.2f%%", read_cov), UVM_LOW)
    `uvm_info("COVERAGE_REPORT", $sformatf("Cross-domain coverage: %0.2f%%", cross_cov), UVM_LOW)
    `uvm_info("COVERAGE_REPORT", $sformatf("Occupancy coverage: %0.2f%%", occ_cov), UVM_LOW)
    `uvm_info("COVERAGE_REPORT", $sformatf("Edge cases coverage: %0.2f%%", edge_cov), UVM_LOW)
    
    real overall_cov = (write_cov + read_cov + cross_cov + occ_cov + edge_cov) / 5.0;
    `uvm_info("COVERAGE_REPORT", $sformatf("Overall coverage: %0.2f%%", overall_cov), UVM_LOW)
    
    if (overall_cov >= 80.0) begin
      `uvm_info("COVERAGE_REPORT", "*** Coverage goal achieved ***", UVM_LOW)
    end else begin
      `uvm_warning("COVERAGE_REPORT", "*** Coverage goal not achieved - consider additional tests ***")
    end
  endfunction
  
endclass

`endif // FIFO_COVERAGE_SV