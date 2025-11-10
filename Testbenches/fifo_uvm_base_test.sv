// ============================================================================
// File:    fifo_uvm_base_test.sv
// Author:  MiniMax Agent
// Purpose: Base test class for dual-clock FIFO UVM testbench
// ============================================================================

`ifndef FIFO_UVM_BASE_TEST_SV
`define FIFO_UVM_BASE_TEST_SV

class fifo_uvm_base_test extends uvm_test;
  `uvm_component_utils(fifo_uvm_base_test)
  
  // Environment components
  fifo_uvm_env env;
  fifo_uvm_env_config env_cfg;
  write_agent_config w_agent_cfg;
  read_agent_config r_agent_cfg;
  
  // Test configuration
  int unsigned wclk_freq_mhz = 100;  // Write clock frequency in MHz
  int unsigned rclk_freq_mhz = 75;   // Read clock frequency in MHz
  int unsigned num_transactions = 1000;
  bit enable_coverage = 1;
  
  function new(string name = "fifo_uvm_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create environment configuration
    env_cfg = fifo_uvm_env_config::type_id::create("env_cfg");
    
    // Configure write agent
    w_agent_cfg = write_agent_config::type_id::create("w_agent_cfg");
    w_agent_cfg.wclk_freq_mhz = wclk_freq_mhz;
    w_agent_cfg.active = UVM_ACTIVE;
    w_agent_cfg.has_coverage = enable_coverage;
    
    // Configure read agent  
    r_agent_cfg = read_agent_config::type_id::create("r_agent_cfg");
    r_agent_cfg.rclk_freq_mhz = rclk_freq_mhz;
    r_agent_cfg.active = UVM_ACTIVE;
    r_agent_cfg.has_coverage = enable_coverage;
    
    // Set agent configurations in environment
    env_cfg.w_agent_cfg = w_agent_cfg;
    env_cfg.r_agent_cfg = r_agent_cfg;
    env_cfg.num_transactions = num_transactions;
    env_cfg.has_scoreboard = 1;
    env_cfg.has_coverage = enable_coverage;
    
    uvm_config_db#(fifo_uvm_env_config)::set(this, "env", "config", env_cfg);
    
    // Create environment
    env = fifo_uvm_env::type_id::create("env", this);
  endfunction
  
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    
    // Print topology
    uvm_top.print_topology();
    
    // Set report verbosity
    uvm_config_db#(int unsigned)::set(this, "*", "recording_detail", UVM_FULL);
    
    // Configure logging
    set_report_default_file_hier("fifo_uvm_simulation.log");
    set_report_severity_action(UVM_INFO, UVM_DISPLAY | UVM_LOG);
    set_report_severity_action(UVM_WARNING, UVM_DISPLAY | UVM_LOG);
    set_report_severity_action(UVM_ERROR, UVM_DISPLAY | UVM_LOG);
    set_report_severity_action(UVM_FATAL, UVM_DISPLAY | UVM_LOG);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    `uvm_info("BASE_TEST", "Starting base test", UVM_LOW)
    
    // Wait for test completion
    wait (env.scoreboard.test_done == 1);
    
    #100ns; // Allow time for final transactions
    
    `uvm_info("BASE_TEST", "Base test completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    // Display final coverage results
    if (enable_coverage) begin
      `uvm_info("COVERAGE", "Coverage Summary:", UVM_LOW)
      // Additional coverage reporting would go here
    end
  endfunction
  
endclass

`endif // FIFO_UVM_BASE_TEST_SV