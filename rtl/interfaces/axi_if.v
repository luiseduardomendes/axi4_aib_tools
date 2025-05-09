interface axi_if;
    // ************** ar channel ***************
    logic [3:0]   arid;
    logic [2:0]   arsize;
    logic [7:0]   arlen;
    logic [1:0]   arburst;
    logic [31:0]  araddr;
    logic         arvalid;
    logic         arready;
    // *****************************************  
    
    // ************* aw channel ****************
    logic [3:0]   awid;
    logic [2:0]   awsize;
    logic [7:0]   awlen;
    logic [1:0]   awburst;
    logic [31:0]  awaddr;
    logic         awvalid;
    logic         awready;
    // *****************************************
        
    // ************* w channel *****************
    logic [3:0]   wid;
    logic [127:0] wdata;
    logic [15:0]  wstrb;
    logic         wlast;
    logic         wvalid;
    logic         wready;
    // *****************************************  
    
    // ************* r channel *****************
    logic [3:0]   rid;
    logic [127:0] rdata;
    logic         rlast;
    logic [1:0]   rresp;
    logic         rvalid;
    logic         rready;
    // *****************************************
      
    // *************** b channel ***************
    logic [3:0]   bid;
    logic [1:0]   bresp;
    logic         bvalid;
    logic         bready;
    // *****************************************

    // Master modport
    modport master (
        output arid, arsize, arlen, arburst, araddr, arvalid,
        input  arready,
        
        output awid, awsize, awlen, awburst, awaddr, awvalid,
        input  awready,
        
        output wid, wdata, wstrb, wlast, wvalid,
        input  wready,
        
        input  rid, rdata, rlast, rresp, rvalid,
        output rready,
        
        input  bid, bresp, bvalid,
        output bready
    );

    // Slave modport
    modport slave (
        input  arid, arsize, arlen, arburst, araddr, arvalid,
        output arready,
        
        input  awid, awsize, awlen, awburst, awaddr, awvalid,
        output awready,
        
        input  wid, wdata, wstrb, wlast, wvalid,
        output wready,
        
        output rid, rdata, rlast, rresp, rvalid,
        input  rready,
        
        output bid, bresp, bvalid,
        input  bready
    );
endinterface