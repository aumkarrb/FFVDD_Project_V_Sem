// ============================================================================
// File:    fifo_sequences.sv
// Author:  MiniMax Agent
// Purpose: Test sequences for FIFO operations
// ============================================================================

`ifndef FIFO_SEQUENCES_SV
`define FIFO_SEQUENCES_SV

// ============================================================================
// Base sequence for write operations
// ============================================================================
class fifo_write_base_sequence extends uvm_sequence#(fifo_write_transaction);
  `uvm_object_utils(fifo_write_base_sequence)
  
  int num_transactions = 10;
  bit enable_random_delay = 1;
  int min_delay = 0;
  int max_delay = 5;
  
  function new(string name = "fifo_write_base_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat (num_transactions) begin
      `uvm_do(req)
      
      if (enable_random_delay) begin
        repeat ($urandom_range(min_delay, max_delay)) @(posedge `vif.wclk);
      end
    end
  endtask
  
endclass

// ============================================================================
// Base sequence for read operations
// ============================================================================
class fifo_read_base_sequence extends uvm_sequence#(fifo_read_transaction);
  `uvm_object_utils(fifo_read_base_sequence)
  
  int num_transactions = 10;
  bit enable_random_delay = 1;
  int min_delay = 0;
  int max_delay = 5;
  
  function new(string name = "fifo_read_base_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat (num_transactions) begin
      `uvm_do(req)
      
      if (enable_random_delay) begin
        repeat ($urandom_range(min_delay, max_delay)) @(posedge `vif.rclk);
      end
    end
  endtask
  
endclass

// ============================================================================
// Normal operation test sequence
// ============================================================================
class fifo_normal_test_seq extends uvm_sequence#(fifo_write_transaction);
  `uvm_object_utils(fifo_normal_test_seq)
  
  fifo_write_transaction write_tr;
  int write_count = 16; // Fill the FIFO
  
  function new(string name = "fifo_normal_test_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    `uvm_info("NORMAL_TEST", "Starting normal operation test", UVM_LOW)
    
    // Write data pattern
    repeat (write_count) begin
      `uvm_create(req)
      req.wdata = $random;
      req.winc = 1;
      `uvm_send(req)
      
      // Wait for clock edge
      @(posedge `vif.wclk);
      
      // Add small delay
      repeat ($urandom_range(0, 2)) @(posedge `vif.wclk);
    end
  endtask
  
endclass

// ============================================================================
// Burst write test sequence
// ============================================================================
class fifo_burst_write_seq extends uvm_sequence#(fifo_write_transaction);
  `uvm_object_utils(fifo_burst_write_seq)
  
  int burst_size = 8;
  bit [7:0] pattern = 8'hAA;
  
  function new(string name = "fifo_burst_write_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    `uvm_info("BURST_WRITE", "Starting burst write test", UVM_LOW)
    
    // Write burst pattern
    repeat (burst_size) begin
      `uvm_create(req)
      req.wdata = pattern;
      req.winc = 1;
      `uvm_send(req)
      
      pattern = pattern ^ 8'h55; // Alternate pattern
      @(posedge `vif.wclk);
    end
  endtask
  
endclass

// ============================================================================
// Stress test sequence - alternating read/write
// ============================================================================
class fifo_stress_test_seq extends uvm_sequence;
  `uvm_object_utils(fifo_stress_test_seq)
  
  fifo_write_sequence write_seq;
  fifo_read_sequence read_seq;
  int num_cycles = 50;
  
  function new(string name = "fifo_stress_test_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    `uvm_info("STRESS_TEST", "Starting stress test with alternating operations", UVM_LOW)
    
    // Start write and read sequences in parallel
    fork
      begin
        write_seq = fifo_write_sequence::type_id::create("write_seq");
        write_seq.start(p_sequencer);
      end
      begin
        read_seq = fifo_read_sequence::type_id::create("read_seq");
        read_seq.start(p_sequencer);
      end
    join
  endtask
  
endclass

// Standalone write sequence for stress testing
class fifo_write_sequence extends uvm_sequence#(fifo_write_transaction);
  `uvm_object_utils(fifo_write_sequence)
  
  function new(string name = "fifo_write_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    forever begin
      `uvm_create(req)
      req.wdata = $random;
      req.winc = $urandom_range(0, 1); // Random enable
      `uvm_send(req)
      @(posedge `vif.wclk);
    end
  endtask
  
endclass

// Standalone read sequence for stress testing
class fifo_read_sequence extends uvm_sequence#(fifo_read_transaction);
  `uvm_object_utils(fifo_read_sequence)
  
  function new(string name = "fifo_read_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    forever begin
      `uvm_create(req)
      req.rinc = $urandom_range(0, 1); // Random enable
      `uvm_send(req)
      @(posedge `vif.rclk);
    end
  endtask
  
endclass

// ============================================================================
// Boundary condition test sequence
// ============================================================================
class fifo_boundary_test_seq extends uvm_sequence#(fifo_write_transaction);
  `uvm_object_utils(fifo_boundary_test_seq)
  
  function new(string name = "fifo_boundary_test_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    `uvm_info("BOUNDARY_TEST", "Starting boundary condition test", UVM_LOW)
    
    // Test sequence: Fill to full, then attempt overflow
    repeat (16) begin // Fill the FIFO
      `uvm_create(req)
      req.wdata = $random;
      req.winc = 1;
      `uvm_send(req)
      @(posedge `vif.wclk);
    end
    
    // Attempt overflow write
    `uvm_create(req)
    req.wdata = $random;
    req.winc = 1; // Should be ignored when full
    `uvm_send(req)
    @(posedge `vif.wclk);
    
    // Test write after reset
    req.wrst_n = 0;
    repeat (3) @(posedge `vif.wclk);
    req.wrst_n = 1;
    repeat (3) @(posedge `vif.wclk);
    
    `uvm_create(req)
    req.wdata = 8'hFF;
    req.winc = 1;
    `uvm_send(req)
    @(posedge `vif.wclk);
  endtask
  
endclass

// ============================================================================
// Clock frequency change test sequence
// ============================================================================
class fifo_freq_change_test_seq extends uvm_sequence#(fifo_write_transaction);
  `uvm_object_utils(fifo_freq_change_test_seq)
  
  function new(string name = "fifo_freq_change_test_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    `uvm_info("FREQ_CHANGE_TEST", "Starting frequency change test", UVM_LOW)
    
    // Test with different frequency patterns
    for (int i = 0; i < 10; i++) begin
      `uvm_create(req)
      req.wdata = $random;
      req.winc = 1;
      `uvm_send(req)
      
      // Vary the timing based on iteration
      repeat (i % 3) @(posedge `vif.wclk);
    end
  endtask
  
endclass

`endif // FIFO_SEQUENCES_SV