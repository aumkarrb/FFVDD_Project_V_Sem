// ============================================================================
// File:    read_agent.sv
// Author:  MiniMax Agent
// Purpose: Agent for read operations in read clock domain
// ============================================================================

`ifndef READ_AGENT_SV
`define READ_AGENT_SV

class read_agent extends uvm_agent;
  `uvm_component_utils(read_agent)
  
  // Agent components
  read_sequencer sequencer;
  read_driver driver;
  read_monitor monitor;
  
  // Configuration
  read_agent_config cfg;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration
    if (!uvm_config_db#(read_agent_config)::get(this, "", "config", cfg)) begin
      `uvm_error("READ_AGENT", "Could not get agent configuration")
    end
    
    // Create components
    if (cfg.active == UVM_ACTIVE) begin
      sequencer = read_sequencer::type_id::create("sequencer", this);
      driver = read_driver::type_id::create("driver", this);
    end
    
    monitor = read_monitor::type_id::create("monitor", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect driver to sequencer
    if (cfg.active == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction
  
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    
    `uvm_info("READ_AGENT", "Read agent built successfully", UVM_LOW)
  endfunction
  
endclass

`endif // READ_AGENT_SV