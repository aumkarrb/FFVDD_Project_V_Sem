// ============================================================================
// File:    read_monitor.sv
// Author:  MiniMax Agent
// Purpose: Monitor for read operations in read clock domain
// ============================================================================

`ifndef READ_MONITOR_SV
`define READ_MONITOR_SV

class read_monitor extends uvm_monitor;
  `uvm_component_utils(read_monitor)
  
  virtual fifo_if vif;
  uvm_analysis_port#(fifo_read_transaction) ap;
  read_agent_config cfg;
  
  // Transaction tracking
  int read_transaction_id = 0;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis port
    ap = new("read_ap", this);
    
    // Get virtual interface
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
      `uvm_error("READ_MONITOR", "Could not get virtual interface")
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    fifo_read_transaction tr;
    
    // Wait for reset deassertion
    wait (vif.rrst_n == 1);
    
    forever begin
      // Wait for read clock edge and valid read condition
      @(posedge vif.rclk);
      
      // Create new transaction
      tr = fifo_read_transaction::type_id::create("read_tr");
      
      // Sample signals
      tr.rinc = vif.rinc;
      tr.rdata = vif.rdata;
      tr.rempty = vif.rempty;
      tr.rd_count = vif.rd_count;
      tr.read_time = $time;
      tr.transaction_id = read_transaction_id++;
      
      // Only analyze when read enable is active
      if (vif.rinc) begin
        `uvm_debug("READ_MONITOR", $sformatf("Monitored: %s", tr.convert2string()))
        ap.write(tr);
      end
    end
  endtask
  
endclass

`endif // READ_MONITOR_SV