// ============================================================================
// File:    write_agent_config.sv
// Author:  MiniMax Agent
// Purpose: Configuration class for write agent
// ============================================================================

`ifndef WRITE_AGENT_CONFIG_SV
`define WRITE_AGENT_CONFIG_SV

class write_agent_config extends uvm_object;
  `uvm_object_utils(write_agent_config)
  
  // Agent configuration
  uvm_active_passive_enum active = UVM_PASSIVE;
  bit has_coverage = 0;
  
  // Clock configuration
  int unsigned wclk_freq_mhz = 100;  // Write clock frequency in MHz
  
  // FIFO configuration (should match DUT)
  int unsigned DSIZE = 8;
  int unsigned ASIZE = 4;
  
  function new(string name = "write_agent_config");
    super.new(name);
  endfunction
  
endclass

`endif // WRITE_AGENT_CONFIG_SV