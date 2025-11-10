// ============================================================================
// File:    write_monitor.sv
// Author:  MiniMax Agent
// Purpose: Monitor for write operations in write clock domain
// ============================================================================

`ifndef WRITE_MONITOR_SV
`define WRITE_MONITOR_SV

class write_monitor extends uvm_monitor;
  `uvm_component_utils(write_monitor)
  
  virtual fifo_if vif;
  uvm_analysis_port#(fifo_write_transaction) ap;
  write_agent_config cfg;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis port
    ap = new("write_ap", this);
    
    // Get virtual interface
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
      `uvm_error("WRITE_MONITOR", "Could not get virtual interface")
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    fifo_write_transaction tr;
    
    // Wait for reset deassertion
    wait (vif.wrst_n == 1);
    
    forever begin
      // Wait for write clock edge and valid write condition
      @(posedge vif.wclk);
      
      // Create new transaction
      tr = fifo_write_transaction::type_id::create("write_tr");
      
      // Sample signals
      tr.wdata = vif.wdata;
      tr.winc = vif.winc;
      tr.wfull = vif.wfull;
      tr.wr_count = vif.wr_count;
      tr.write_time = $time;
      
      // Only analyze when write enable is active
      if (vif.winc) begin
        `uvm_debug("WRITE_MONITOR", $sformatf("Monitored: %s", tr.convert2string()))
        ap.write(tr);
      end
    end
  endtask
  
endclass

`endif // WRITE_MONITOR_SV