// ============================================================================
// File:    fifo_uvm_tests.sv
// Author:  MiniMax Agent
// Purpose: Specific test classes for different FIFO scenarios
// ============================================================================

`ifndef FIFO_UVM_TESTS_SV
`define FIFO_UVM_TESTS_SV

// ============================================================================
// Normal operation test
// ============================================================================
class fifo_normal_test extends fifo_uvm_base_test;
  `uvm_component_utils(fifo_normal_test)
  
  fifo_normal_test_seq write_seq;
  fifo_read_sequence read_seq;
  
  function new(string name = "fifo_normal_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    num_transactions = 32; // Fill and empty the FIFO
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    // Start write sequence on write sequencer
    fork
      begin
        write_seq = fifo_normal_test_seq::type_id::create("write_seq");
        write_seq.start(w_agent.sequencer);
      end
      begin
        // Start read sequence on read sequencer  
        read_seq = fifo_read_sequence::type_id::create("read_seq");
        read_seq.start(r_agent.sequencer);
      end
    join
    
    phase.drop_objection(this);
  endtask
  
endclass

// ============================================================================
// Stress test with alternating operations
// ============================================================================
class fifo_stress_test extends fifo_uvm_base_test;
  `uvm_object_utils(fifo_stress_test)
  
  fifo_stress_test_seq stress_seq;
  
  function new(string name = "fifo_stress_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Higher frequency to stress the system
    wclk_freq_mhz = 150;
    rclk_freq_mhz = 120;
    num_transactions = 200;
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    // Start stress test sequence
    stress_seq = fifo_stress_test_seq::type_id::create("stress_seq");
    stress_seq.start(w_agent.sequencer);
    
    phase.drop_objection(this);
  endtask
  
endclass

// ============================================================================
// Burst write test
// ============================================================================
class fifo_burst_test extends fifo_uvm_base_test;
  `uvm_component_utils(fifo_burst_test)
  
  fifo_burst_write_seq burst_seq;
  fifo_read_sequence read_seq;
  
  function new(string name = "fifo_burst_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    num_transactions = 16;
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    fork
      begin
        // Burst write pattern
        burst_seq = fifo_burst_write_seq::type_id::create("burst_seq");
        burst_seq.start(w_agent.sequencer);
      end
      begin
        // Random reads
        read_seq = fifo_read_sequence::type_id::create("read_seq");
        #100ns; // Small delay before starting reads
        read_seq.start(r_agent.sequencer);
      end
    join
    
    phase.drop_objection(this);
  endtask
  
endclass

// ============================================================================
// Boundary condition test
// ============================================================================
class fifo_boundary_test extends fifo_uvm_base_test;
  `uvm_component_utils(fifo_boundary_test)
  
  fifo_boundary_test_seq boundary_seq;
  
  function new(string name = "fifo_boundary_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    // Test boundary conditions
    boundary_seq = fifo_boundary_test_seq::type_id::create("boundary_seq");
    boundary_seq.start(w_agent.sequencer);
    
    phase.drop_objection(this);
  endtask
  
endclass

// ============================================================================
// Clock frequency mismatch test
// ============================================================================
class fifo_freq_mismatch_test extends fifo_uvm_base_test;
  `uvm_component_utils(fifo_freq_mismatch_test)
  
  fifo_freq_change_test_seq freq_seq;
  fifo_read_sequence read_seq;
  
  function new(string name = "fifo_freq_mismatch_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Significantly different clock frequencies
    wclk_freq_mhz = 200;
    rclk_freq_mhz = 50;
    num_transactions = 100;
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    fork
      begin
        // Test with frequency variations
        freq_seq = fifo_freq_change_test_seq::type_id::create("freq_seq");
        freq_seq.start(w_agent.sequencer);
      end
      begin
        // Continuous reads
        read_seq = fifo_read_sequence::type_id::create("read_seq");
        #50ns; // Start reads after some writes
        read_seq.start(r_agent.sequencer);
      end
    join
    
    phase.drop_objection(this);
  endtask
  
endclass

// ============================================================================
// Reset test - verify behavior during and after reset
// ============================================================================
class fifo_reset_test extends fifo_uvm_base_test;
  `uvm_component_utils(fifo_reset_test)
  
  fifo_normal_test_seq write_seq;
  fifo_read_sequence read_seq;
  virtual fifo_if vif;
  
  function new(string name = "fifo_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    num_transactions = 50;
    
    // Get virtual interface for reset control
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
      `uvm_error("RESET_TEST", "Could not get virtual interface")
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    // Start initial operations
    fork
      begin
        write_seq = fifo_normal_test_seq::type_id::create("write_seq");
        write_seq.start(w_agent.sequencer);
      end
      begin
        read_seq = fifo_read_sequence::type_id::create("read_seq");
        #25ns;
        read_seq.start(r_agent.sequencer);
      end
    join
    
    // Issue reset during operation
    `uvm_info("RESET_TEST", "Issuing write domain reset", UVM_LOW)
    vif.generate_wrst(1);
    
    #100ns;
    
    `uvm_info("RESET_TEST", "Issuing read domain reset", UVM_LOW)
    vif.generate_rrst(1);
    
    // Continue operations after reset
    #50ns;
    
    fork
      begin
        write_seq = fifo_normal_test_seq::type_id::create("write_seq2");
        write_seq.start(w_agent.sequencer);
      end
      begin
        read_seq = fifo_read_sequence::type_id::create("read_seq2");
        read_seq.start(r_agent.sequencer);
      end
    join
    
    phase.drop_objection(this);
  endtask
  
endclass

// ============================================================================
// Data integrity test - verify all data patterns
// ============================================================================
class fifo_data_integrity_test extends fifo_uvm_base_test;
  `uvm_component_utils(fifo_data_integrity_test)
  
  function new(string name = "fifo_data_integrity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    // Write specific data patterns
    fork
      begin
        // Write all possible data values
        for (int i = 0; i < 256; i++) begin
          fifo_write_transaction tr;
          `uvm_create(req)
          req.wdata = i[7:0];
          req.winc = 1;
          `uvm_send(req)
          @(posedge w_agent.monitor.vif.wclk);
          
          if (i % 16 == 15) begin
            #10ns; // Small delay every 16 writes
          end
        end
      end
      begin
        // Read all data back
        #50ns; // Delay to let some data accumulate
        for (int i = 0; i < 256; i++) begin
          fifo_read_transaction tr;
          `uvm_create(req)
          req.rinc = 1;
          `uvm_send(req)
          @(posedge r_agent.monitor.vif.rclk);
          
          if (i % 16 == 15) begin
            #10ns; // Small delay every 16 reads
          end
        end
      end
    join
    
    phase.drop_objection(this);
  endtask
  
endclass

`endif // FIFO_UVM_TESTS_SV