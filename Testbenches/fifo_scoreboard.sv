// ============================================================================
// File:    fifo_scoreboard.sv
// Author:  MiniMax Agent
// Purpose: Scoreboard for FIFO data integrity validation
// ============================================================================

`ifndef FIFO_SCOREBOARD_SV
`define FIFO_SCOREBOARD_SV

class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)
  
  // Expected data queue (simulated reference model)
  bit [7:0] expected_data[$];
  
  // Analysis ports
  uvm_analysis_export#(fifo_write_transaction) w_ap;
  uvm_analysis_export#(fifo_read_transaction) r_ap;
  
  // Analysis FIFOs for cross-domain communication
  uvm_tlm_analysis_fifo#(fifo_write_transaction) w_fifo;
  uvm_tlm_analysis_fifo#(fifo_read_transaction) r_fifo;
  
  // Configuration
  fifo_uvm_env_config cfg;
  
  // Scoreboard state
  bit test_done = 0;
  int total_writes = 0;
  int total_reads = 0;
  int mismatches = 0;
  int underflow_errors = 0;
  int overflow_errors = 0;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis exports and FIFOs
    w_ap = new("write_ap", this);
    r_ap = new("read_ap", this);
    w_fifo = new("w_fifo", this);
    r_fifo = new("r_fifo", this);
    
    // Get configuration
    if (!uvm_config_db#(fifo_uvm_env_config)::get(this, "", "config", cfg)) begin
      `uvm_error("SCOREBOARD", "Could not get environment configuration")
    end
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect analysis ports to FIFOs
    w_ap.connect(w_fifo.analysis_export);
    r_ap.connect(r_fifo.analysis_export);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    fork
      process_write_transactions();
      process_read_transactions();
      monitor_test_completion();
    join
  endtask
  
  virtual task process_write_transactions();
    fifo_write_transaction w_tr;
    
    forever begin
      w_fifo.get(w_tr);
      
      if (w_tr.winc && !w_tr.wfull) begin
        // Valid write operation
        expected_data.push_back(w_tr.wdata);
        total_writes++;
        
        `uvm_debug("SCOREBOARD", $sformatf("Write: 0x%2h, Queue size: %0d", 
                                          w_tr.wdata, expected_data.size()))
      end else if (w_tr.winc && w_tr.wfull) begin
        // Overflow detected
        overflow_errors++;
        `uvm_error("SCOREBOARD", $sformatf("Overflow detected: Write attempted while full at time %0t", 
                                          w_tr.write_time))
      end
    end
  endtask
  
  virtual task process_read_transactions();
    fifo_read_transaction r_tr;
    bit [7:0] expected_data_item;
    
    forever begin
      r_fifo.get(r_tr);
      
      if (r_tr.rinc) begin
        if (expected_data.size() > 0) begin
          // Valid read operation
          expected_data_item = expected_data.pop_front();
          total_reads++;
          
          // Check data integrity
          if (r_tr.rdata !== expected_data_item) begin
            mismatches++;
            `uvm_error("SCOREBOARD", $sformatf("Data mismatch: Expected 0x%2h, Got 0x%2h at time %0t",
                                              expected_data_item, r_tr.rdata, r_tr.read_time))
          end else begin
            `uvm_debug("SCOREBOARD", $sformatf("Read: 0x%2h matches expected, Queue size: %0d",
                                              r_tr.rdata, expected_data.size()))
          end
        end else begin
          // Underflow detected
          underflow_errors++;
          `uvm_error("SCOREBOARD", $sformatf("Underflow detected: Read attempted while empty at time %0t",
                                            r_tr.read_time))
        end
      end
    end
  endtask
  
  virtual task monitor_test_completion();
    // Wait for some time or condition to end the test
    wait (total_writes >= cfg.num_transactions);
    #1us; // Allow time for remaining reads
    test_done = 1;
  endtask
  
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info("SCOREBOARD_REPORT", "=== FIFO Scoreboard Results ===", UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Total writes: %0d", total_writes), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Total reads: %0d", total_reads), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Data mismatches: %0d", mismatches), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Underflow errors: %0d", underflow_errors), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Overflow errors: %0d", overflow_errors), UVM_LOW)
    `uvm_info("SCOREBOARD_REPORT", $sformatf("Final queue size: %0d", expected_data.size()), UVM_LOW)
    
    if (mismatches == 0 && underflow_errors == 0 && overflow_errors == 0) begin
      `uvm_info("SCOREBOARD_REPORT", "*** TEST PASSED ***", UVM_LOW)
    end else begin
      `uvm_error("SCOREBOARD_REPORT", "*** TEST FAILED ***")
    end
  endfunction
  
endclass

`endif // FIFO_SCOREBOARD_SV