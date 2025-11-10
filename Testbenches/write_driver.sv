// ============================================================================
// File:    write_driver.sv
// Author:  MiniMax Agent
// Purpose: Driver for write operations in write clock domain
// ============================================================================

`ifndef WRITE_DRIVER_SV
`define WRITE_DRIVER_SV

class write_driver extends uvm_driver#(fifo_write_transaction);
  `uvm_component_utils(write_driver)
  
  virtual fifo_if vif;
  write_agent_config cfg;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
      `uvm_error("WRITE_DRIVER", "Could not get virtual interface")
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Reset handling
    wait (vif.wrst_n == 1);
    
    forever begin
      seq_item_port.get_next_item(req);
      
      // Drive the transaction
      drive_transaction(req);
      
      // Set timing
      req.write_time = $time;
      
      seq_item_port.item_done();
    end
  endtask
  
  virtual task drive_transaction(fifo_write_transaction tr);
    
    // Wait for write clock edge
    @(posedge vif.wclk);
    
    // Drive signals
    vif.wdata <= tr.wdata;
    vif.winc  <= tr.winc;
    
    // Monitor for backpressure
    if (vif.wfull) begin
      `uvm_info("WRITE_DRIVER", "Write attempted while FIFO full", UVM_HIGH)
      tr.wfull = 1;
    end else begin
      tr.wfull = 0;
    end
    
    // Capture write count
    tr.wr_count = vif.wr_count;
    
    `uvm_debug("WRITE_DRIVER", $sformatf("Writing: %s", tr.convert2string()))
  endtask
  
endclass

`endif // WRITE_DRIVER_SV