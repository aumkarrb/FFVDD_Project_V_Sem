// ============================================================================
// File:    write_agent.sv
// Author:  MiniMax Agent
// Purpose: Agent for write operations in write clock domain
// ============================================================================

`ifndef WRITE_AGENT_SV
`define WRITE_AGENT_SV

class write_agent extends uvm_agent;
  `uvm_component_utils(write_agent)
  
  // Agent components
  write_sequencer sequencer;
  write_driver driver;
  write_monitor monitor;
  
  // Configuration
  write_agent_config cfg;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration
    if (!uvm_config_db#(write_agent_config)::get(this, "", "config", cfg)) begin
      `uvm_error("WRITE_AGENT", "Could not get agent configuration")
    end
    
    // Create components
    if (cfg.active == UVM_ACTIVE) begin
      sequencer = write_sequencer::type_id::create("sequencer", this);
      driver = write_driver::type_id::create("driver", this);
    end
    
    monitor = write_monitor::type_id::create("monitor", this);
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
    
    `uvm_info("WRITE_AGENT", "Write agent built successfully", UVM_LOW)
  endfunction
  
endclass

`endif // WRITE_AGENT_SV