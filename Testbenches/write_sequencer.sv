// ============================================================================
// File:    write_sequencer.sv
// Author:  MiniMax Agent
// Purpose: Sequencer for write operations
// ============================================================================

`ifndef WRITE_SEQUENCER_SV
`define WRITE_SEQUENCER_SV

class write_sequencer extends uvm_sequencer#(fifo_write_transaction);
  `uvm_component_utils(write_sequencer)
  
  write_agent_config cfg;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
endclass

`endif // WRITE_SEQUENCER_SV