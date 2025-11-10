// ============================================================================
// File:    read_agent_config.sv
// Author:  MiniMax Agent
// Purpose: Configuration class for read agent
// ============================================================================

`ifndef READ_AGENT_CONFIG_SV
`define READ_AGENT_CONFIG_SV

class read_agent_config extends uvm_object;
  `uvm_object_utils(read_agent_config)
  
  // Agent configuration
  uvm_active_passive_enum active = UVM_PASSIVE;
  bit has_coverage = 0;
  
  // Clock configuration
  int unsigned rclk_freq_mhz = 100;  // Read clock frequency in MHz
  
  // FIFO configuration (should match DUT)
  int unsigned DSIZE = 8;
  int unsigned ASIZE = 4;
  
  function new(string name = "read_agent_config");
    super.new(name);
  endfunction
  
endclass

`endif // READ_AGENT_CONFIG_SV