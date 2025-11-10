// ============================================================================
// File:    fifo_uvm_env.sv
// Author:  MiniMax Agent
// Purpose: UVM environment for dual-clock FIFO
// ============================================================================

`ifndef FIFO_UVM_ENV_SV
`define FIFO_UVM_ENV_SV

class fifo_uvm_env extends uvm_env;
  `uvm_component_utils(fifo_uvm_env)
  
  // Environment configuration
  fifo_uvm_env_config cfg;
  
  // Agent instances
  write_agent w_agent;
  read_agent r_agent;
  
  // Scoreboard and coverage
  fifo_scoreboard scoreboard;
  fifo_coverage coverage;
  
  // Analysis components
  cross_domain_analyzer cross_analyzer;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration
    if (!uvm_config_db#(fifo_uvm_env_config)::get(this, "", "config", cfg)) begin
      `uvm_error("ENV", "Could not get environment configuration")
    end
    
    // Validate configuration
    if (!cfg.is_valid()) begin
      `uvm_fatal("ENV", "Invalid environment configuration")
    end
    
    // Create agents
    w_agent = write_agent::type_id::create("w_agent", this);
    r_agent = read_agent::type_id::create("r_agent", this);
    
    // Set agent configurations
    uvm_config_db#(write_agent_config)::set(this, "w_agent", "config", cfg.w_agent_cfg);
    uvm_config_db#(read_agent_config)::set(this, "r_agent", "config", cfg.r_agent_cfg);
    
    // Create scoreboard if enabled
    if (cfg.has_scoreboard) begin
      scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
      uvm_config_db#(fifo_uvm_env_config)::set(this, "scoreboard", "config", cfg);
    end
    
    // Create coverage if enabled
    if (cfg.has_coverage) begin
      coverage = fifo_coverage::type_id::create("coverage", this);
      uvm_config_db#(fifo_uvm_env_config)::set(this, "coverage", "config", cfg);
    end
    
    // Create cross-domain analyzer
    cross_analyzer = cross_domain_analyzer::type_id::create("cross_analyzer", this);
    
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect monitors to scoreboard
    if (cfg.has_scoreboard && scoreboard != null) begin
      w_agent.monitor.ap.connect(scoreboard.w_ap);
      r_agent.monitor.ap.connect(scoreboard.r_ap);
    end
    
    // Connect cross-domain analyzer
    w_agent.monitor.ap.connect(cross_analyzer.w_ap);
    r_agent.monitor.ap.connect(cross_analyzer.r_ap);
    
    // Connect coverage to cross-domain analyzer
    if (cfg.has_coverage && coverage != null) begin
      cross_analyzer.ap.connect(coverage.analysis_export);
    end
    
  endfunction
  
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    
    `uvm_info("ENV", "FIFO UVM environment built successfully", UVM_LOW)
    `uvm_info("ENV", $sformatf("Write clock: %0d MHz", cfg.w_agent_cfg.wclk_freq_mhz), UVM_LOW)
    `uvm_info("ENV", $sformatf("Read clock: %0d MHz", cfg.r_agent_cfg.rclk_freq_mhz), UVM_LOW)
    `uvm_info("ENV", $sformatf("Data size: %0d bits", cfg.DSIZE), UVM_LOW)
    `uvm_info("ENV", $sformatf("Address size: %0d bits", cfg.ASIZE), UVM_LOW)
  endfunction
  
endclass

// Cross-domain analyzer for combining transactions
class cross_domain_analyzer extends uvm_component;
  `uvm_component_utils(cross_domain_analyzer)
  
  // Analysis ports
  uvm_analysis_export#(fifo_write_transaction) w_ap;
  uvm_analysis_export#(fifo_read_transaction) r_ap;
  uvm_analysis_port#(fifo_combined_transaction) ap;
  
  // Internal FIFOs for transaction coordination
  uvm_tlm_analysis_fifo#(fifo_write_transaction) w_fifo;
  uvm_tlm_analysis_fifo#(fifo_read_transaction) r_fifo;
  
  // Transaction tracking
  int write_count = 0;
  int read_count = 0;
  int latency_sum = 0;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    w_ap = new("w_ap", this);
    r_ap = new("r_ap", this);
    ap = new("ap", this);
    w_fifo = new("w_fifo", this);
    r_fifo = new("r_fifo", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    w_ap.connect(w_fifo.analysis_export);
    r_ap.connect(r_fifo.analysis_export);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    fork
      process_combined_transactions();
    join
  endtask
  
  virtual task process_combined_transactions();
    fifo_write_transaction w_tr;
    fifo_read_transaction r_tr;
    fifo_combined_transaction comb_tr;
    
    forever begin
      #0; // Ensure proper scheduling
      
      // Try to get write transaction
      if (w_fifo.try_get(w_tr)) begin
        comb_tr = fifo_combined_transaction::type_id::create("comb_tr");
        
        comb_tr.write_tx = w_tr;
        comb_tr.data = w_tr.wdata;
        comb_tr.valid_write = w_tr.winc && !w_tr.wfull;
        comb_tr.valid_read = 0;
        comb_tr.latency_cycles = 0;
        
        `uvm_debug("CROSS_ANALYZER", $sformatf("Created combined TX for write: %s", comb_tr.convert2string()))
        ap.write(comb_tr);
      end
      
      // Try to get read transaction
      if (r_fifo.try_get(r_tr)) begin
        comb_tr = fifo_combined_transaction::type_id::create("comb_tr");
        
        comb_tr.read_tx = r_tr;
        comb_tr.data = r_tr.rdata;
        comb_tr.valid_write = 0;
        comb_tr.valid_read = r_tr.rinc && !r_tr.rempty;
        comb_tr.latency_cycles = 0; // Would need timestamp correlation to calculate
        
        `uvm_debug("CROSS_ANALYZER", $sformatf("Created combined TX for read: %s", comb_tr.convert2string()))
        ap.write(comb_tr);
      end
      
      // Small delay to prevent infinite loop
      #1ps;
    end
  endtask
  
endclass

`endif // FIFO_UVM_ENV_SV