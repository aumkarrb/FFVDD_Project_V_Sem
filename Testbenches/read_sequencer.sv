// ============================================================================
// File:    read_sequencer.sv
// Author:  MiniMax Agent
// Purpose: Sequencer for read operations
// ============================================================================

`ifndef READ_SEQUENCER_SV
`define READ_SEQUENCER_SV

class read_sequencer extends uvm_sequencer#(fifo_read_transaction);
  `uvm_component_utils(read_sequencer)
  
  read_agent_config cfg;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
endclass

`endif // READ_SEQUENCER_SV