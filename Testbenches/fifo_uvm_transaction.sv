// ============================================================================
// File:    fifo_uvm_transaction.sv
// Author:  MiniMax Agent
// Purpose: Transaction classes for FIFO operations
// ============================================================================

`ifndef FIFO_UVM_TRANSACTION_SV
`define FIFO_UVM_TRANSACTION_SV

// Write transaction for write clock domain
class fifo_write_transaction extends uvm_sequence_item;
  `uvm_object_utils(fifo_write_transaction)
  
  rand bit [7:0] wdata;        // Write data
  rand bit        winc;         // Write enable
  bit             wfull;        // Full flag (monitored)
  bit [4:0]       wr_count;     // Write count (monitored)
  
  // Timing information
  time            write_time;
  
  constraint data_c {
    wdata dist {8'h00 := 10, 8'hFF := 10, [8'h01:8'hFE] := 80};
  }
  
  constraint enable_c {
    winc dist {1 := 70, 0 := 30};  // More writes than idle
  }
  
  function new(string name = "fifo_write_transaction");
    super.new(name);
  endfunction
  
  function void do_copy(uvm_object rhs);
    fifo_write_transaction rhs_;
    super.do_copy(rhs);
    if (rhs_ == null) return;
    wdata = rhs_.wdata;
    winc = rhs_.winc;
    wfull = rhs_.wfull;
    wr_count = rhs_.wr_count;
    write_time = rhs_.write_time;
  endfunction
  
  function string convert2string();
    return $sformatf("wdata=0x%2h, winc=%b, wfull=%b, wr_count=%0d, time=%0t",
                     wdata, winc, wfull, wr_count, write_time);
  endfunction
  
  function bit do_compare(uvm_object rhs, uvm_comparer comparer = null);
    fifo_write_transaction rhs_;
    do_compare = super.do_compare(rhs, comparer);
    if (rhs_ == null) return 0;
    do_compare &= comparer.compare_field("wdata", wdata, rhs_.wdata, 8);
    do_compare &= comparer.compare_field("winc", winc, rhs_.winc, 1);
  endfunction
  
endclass

// Read transaction for read clock domain
class fifo_read_transaction extends uvm_sequence_item;
  `uvm_object_utils(fifo_read_transaction)
  
  rand bit        rinc;         // Read enable
  bit      [7:0]  rdata;        // Read data (monitored)
  bit             rempty;       // Empty flag (monitored)
  bit      [4:0]  rd_count;     // Read count (monitored)
  
  // Timing information
  time            read_time;
  int             transaction_id;
  
  constraint enable_c {
    rinc dist {1 := 70, 0 := 30};  // More reads than idle
  }
  
  function new(string name = "fifo_read_transaction");
    super.new(name);
  endfunction
  
  function void do_copy(uvm_object rhs);
    fifo_read_transaction rhs_;
    super.do_copy(rhs);
    if (rhs_ == null) return;
    rinc = rhs_.rinc;
    rdata = rhs_.rdata;
    rempty = rhs_.rempty;
    rd_count = rhs_.rd_count;
    read_time = rhs_.read_time;
    transaction_id = rhs_.transaction_id;
  endfunction
  
  function string convert2string();
    return $sformatf("rinc=%b, rdata=0x%2h, rempty=%b, rd_count=%0d, id=%0d, time=%0t",
                     rinc, rdata, rempty, rd_count, transaction_id, read_time);
  endfunction
  
  function bit do_compare(uvm_object rhs, uvm_comparer comparer = null);
    fifo_read_transaction rhs_;
    do_compare = super.do_compare(rhs, comparer);
    if (rhs_ == null) return 0;
    do_compare &= comparer.compare_field("rinc", rinc, rhs_.rinc, 1);
    do_compare &= comparer.compare_field("rdata", rdata, rhs_.rdata, 8);
  endfunction
  
endclass

// Combined transaction for cross-domain analysis
class fifo_combined_transaction extends uvm_sequence_item;
  `uvm_object_utils(fifo_combined_transaction)
  
  fifo_write_transaction write_tx;
  fifo_read_transaction read_tx;
  
  bit [7:0] data;              // Data being transferred
  bit       valid_write;       // Valid write operation
  bit       valid_read;        // Valid read operation
  int       latency_cycles;    // Latency in cycles
  
  function new(string name = "fifo_combined_transaction");
    super.new(name);
  endfunction
  
  function void do_copy(uvm_object rhs);
    fifo_combined_transaction rhs_;
    super.do_copy(rhs);
    if (rhs_ == null) return;
    data = rhs_.data;
    valid_write = rhs_.valid_write;
    valid_read = rhs_.valid_read;
    latency_cycles = rhs_.latency_cycles;
  endfunction
  
  function string convert2string();
    return $sformatf("data=0x%2h, valid_write=%b, valid_read=%b, latency=%0d",
                     data, valid_write, valid_read, latency_cycles);
  endfunction
  
endclass

`endif // FIFO_UVM_TRANSACTION_SV