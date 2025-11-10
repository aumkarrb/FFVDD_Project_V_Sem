// ============================================================================
// File:    fifo_uvm_env_config.sv
// Author:  MiniMax Agent
// Purpose: Configuration class for FIFO UVM environment
// ============================================================================

`ifndef FIFO_UVM_ENV_CONFIG_SV
`define FIFO_UVM_ENV_CONFIG_SV

class fifo_uvm_env_config extends uvm_object;
  `uvm_object_utils(fifo_uvm_env_config)
  
  // Agent configurations
  write_agent_config w_agent_cfg;
  read_agent_config r_agent_cfg;
  
  // Environment configuration
  bit has_scoreboard = 1;
  bit has_coverage = 1;
  int unsigned num_transactions = 1000;
  
  // DUT configuration (should match actual DUT parameters)
  int unsigned DSIZE = 8;
  int unsigned ASIZE = 4;
  
  function new(string name = "fifo_uvm_env_config");
    super.new(name);
  endfunction
  
  // Utility function to check if configuration is valid
  function bit is_valid();
    if (w_agent_cfg == null || r_agent_cfg == null) begin
      `uvm_error("ENV_CONFIG", "Agent configurations are not set")
      return 0;
    end
    
    if (w_agent_cfg.DSIZE != DSIZE || r_agent_cfg.DSIZE != DSIZE) begin
      `uvm_error("ENV_CONFIG", "Data size mismatch in agent configurations")
      return 0;
    end
    
    if (w_agent_cfg.ASIZE != ASIZE || r_agent_cfg.ASIZE != ASIZE) begin
      `uvm_error("ENV_CONFIG", "Address size mismatch in agent configurations")
      return 0;
    end
    
    return 1;
  endfunction
  
endclass

`endif // FIFO_UVM_ENV_CONFIG_SV