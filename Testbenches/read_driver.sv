// ============================================================================
// File:    read_driver.sv
// Author:  MiniMax Agent
// Purpose: Driver for read operations in read clock domain
// ============================================================================

`ifndef READ_DRIVER_SV
`define READ_DRIVER_SV

class read_driver extends uvm_driver#(fifo_read_transaction);
  `uvm_component_utils(read_driver)
  
  virtual fifo_if vif;
  read_agent_config cfg;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
      `uvm_error("READ_DRIVER", "Could not get virtual interface")
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Reset handling
    wait (vif.rrst_n == 1);
    
    forever begin
      seq_item_port.get_next_item(req);
      
      // Drive the transaction
      drive_transaction(req);
      
      // Set timing
      req.read_time = $time;
      
      seq_item_port.item_done();
    end
  endtask
  
  virtual task drive_transaction(fifo_read_transaction tr);
    
    // Wait for read clock edge
    @(posedge vif.rclk);
    
    // Drive signals
    vif.rinc <= tr.rinc;
    
    // Monitor for underflow
    if (vif.rempty) begin
      `uvm_info("READ_DRIVER", "Read attempted while FIFO empty", UVM_HIGH)
      tr.rempty = 1;
    end else begin
      tr.rempty = 0;
    end
    
    // Capture read data and count
    tr.rdata = vif.rdata;
    tr.rd_count = vif.rd_count;
    
    `uvm_debug("READ_DRIVER", $sformatf("Reading: %s", tr.convert2string()))
  endtask
  
endclass

`endif // READ_DRIVER_SV