`timescale 1ns / 1ps

import axi_vip_pkg::*;
import test_axi_vip_0_0_pkg::*; 

`define ADDR_USER_CTRL      6'h10
`define ADDR_BYTE_LEN_DATA  6'h14
`define ADDR_SRC_DATA       6'h18
`define ADDR_DST_DATA       6'h1c
    
`define START               32'd1
`define DONE                32'd2
`define DATA_SIZE           1024
    
`define SRC_ADDR            32'h1000_0000
`define DST_ADDR            32'h2000_0000

module dmac_tb(

    );
    
    parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12;
    parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32;
    parameter integer C_M_AXI_ADDR_WIDTH = 32;
    parameter integer C_M_AXI_DATA_WIDTH = 256;
    
    logic                                    ap_clk;
    logic                                    ap_rstn;
    logic                                    s_axi_control_awvalid;
    logic                                    s_axi_control_awready;
    logic [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_awaddr;
    logic                                    s_axi_control_wvalid;
    logic                                    s_axi_control_wready;
    logic [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_wdata;
    logic [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb;
    logic                                    s_axi_control_arvalid;
    logic                                    s_axi_control_arready;
    logic [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_araddr;
    logic                                    s_axi_control_rvalid;
    logic                                    s_axi_control_rready;
    logic [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_rdata;
    logic                                    s_axi_control_bvalid;
    logic                                    s_axi_control_bready;
    logic [1:0]                              s_axi_control_bresp;
    
    // AMBA AXI Interface (AW Channel)
    logic    [31:0]      m_axi_awaddr;
    logic    [7:0]       m_axi_awlen;
    logic    [2:0]       m_axi_awsize;
    logic    [1:0]       m_axi_awburst;
    logic                m_axi_awvalid;
    logic                m_axi_awready;
    
    // AMBA AXI Interface (W Channel)
    logic    [255:0]      m_axi_wdata;
    logic    [31:0]       m_axi_wstrb;
    logic                m_axi_wlast;
    logic                m_axi_wvalid;
    logic                m_axi_wready;
    
    // AMBA AXI Interface (B Channel)
    logic    [1:0]       m_axi_bresp;
    logic                m_axi_bvalid;
    logic                m_axi_bready;
    
    // AMBA AXI Interface (AR Channel)
    logic    [31:0]      m_axi_araddr;
    logic    [7:0]       m_axi_arlen;
    logic    [2:0]       m_axi_arsize;
    logic    [1:0]       m_axi_arburst;
    logic                m_axi_arvalid;
    logic                m_axi_arready;
    
    // AMBA AXI Interface (R Channel)
    logic    [3:0]       m_axi_rid;
    logic    [255:0]      m_axi_rdata;
    logic    [1:0]       m_axi_rresp;
    logic                m_axi_rlast;
    logic                m_axi_rvalid;
    logic                m_axi_rready;
       
        
   
   
    test_axi_vip_0_0_slv_mem_t slv_agent0;

    initial begin
            // AXI VIP Slave Agent 생성 및 시작
        slv_agent0 = new("slv_agent0", axi_vip_inst.test_i.axi_vip_0.inst.IF);
        slv_agent0.start_slave();
        slv_agent0.set_verbosity(400);
    end

    DMAC_TOP #(
        .C_S_AXI_CONTROL_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
        .C_S_AXI_CONTROL_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
    ) u_engine (
        .ap_clk    ( ap_clk                ),
        .ap_rstn    ( ap_rstn                ),
    
        // Control AXI Interface (unchanged)
        .s_axi_control_awvalid    ( s_axi_control_awvalid ),
        .s_axi_control_awready    ( s_axi_control_awready ),
        .s_axi_control_awaddr     ( s_axi_control_awaddr  ),
        .s_axi_control_wvalid     ( s_axi_control_wvalid  ),
        .s_axi_control_wready     ( s_axi_control_wready  ),
        .s_axi_control_wdata      ( s_axi_control_wdata   ),
        .s_axi_control_wstrb      ( s_axi_control_wstrb   ),
        .s_axi_control_arvalid    ( s_axi_control_arvalid ),
        .s_axi_control_arready    ( s_axi_control_arready ),
        .s_axi_control_araddr     ( s_axi_control_araddr  ),
        .s_axi_control_rvalid     ( s_axi_control_rvalid  ),
        .s_axi_control_rready     ( s_axi_control_rready  ),
        .s_axi_control_rdata      ( s_axi_control_rdata   ),
        .s_axi_control_rresp      ( s_axi_control_rresp   ),
        .s_axi_control_bvalid     ( s_axi_control_bvalid  ),
        .s_axi_control_bready     ( s_axi_control_bready  ),
        .s_axi_control_bresp      ( s_axi_control_bresp   ),
    
        // AXI Master 연결 (VIP Slave 인터페이스와 직접 연결)
        .m_axi_awaddr    ( m_axi_awaddr    ),
        .m_axi_awlen     ( m_axi_awlen     ),
        .m_axi_awsize    ( m_axi_awsize    ),
        .m_axi_awburst   ( m_axi_awburst   ),
        .m_axi_awvalid   ( m_axi_awvalid   ),
        .m_axi_awready   ( m_axi_awready   ),
    
        .m_axi_wdata     ( m_axi_wdata     ),
        .m_axi_wstrb     ( m_axi_wstrb     ),
        .m_axi_wlast     ( m_axi_wlast     ),
        .m_axi_wvalid    ( m_axi_wvalid    ),
        .m_axi_wready    ( m_axi_wready    ),
    
        .m_axi_bresp     ( m_axi_bresp     ),
        .m_axi_bvalid    ( m_axi_bvalid    ),
        .m_axi_bready    ( m_axi_bready    ),
    
        .m_axi_araddr    ( m_axi_araddr    ),
        .m_axi_arlen     ( m_axi_arlen     ),
        .m_axi_arsize    ( m_axi_arsize    ),
        .m_axi_arburst   ( m_axi_arburst   ),
        .m_axi_arvalid   ( m_axi_arvalid   ),
        .m_axi_arready   ( m_axi_arready   ),
    
        .m_axi_rdata     ( m_axi_rdata     ),
        .m_axi_rresp     ( m_axi_rresp     ),
        .m_axi_rlast     ( m_axi_rlast     ),
        .m_axi_rvalid    ( m_axi_rvalid    ),
        .m_axi_rready    ( m_axi_rready    )
    );


  test_wrapper axi_vip_inst
       (.S_AXI_araddr(m_axi_araddr),
        .S_AXI_arburst(m_axi_arburst),
        .S_AXI_arid('d0),
        .S_AXI_arcache('d0),
        .S_AXI_arlen(m_axi_arlen),
        .S_AXI_arlock('d0),
        .S_AXI_arprot('d0),
        .S_AXI_arqos('d0),
        .S_AXI_arready(m_axi_arready),
        .S_AXI_arregion('d0),
        .S_AXI_arsize(m_axi_arsize),
        .S_AXI_arvalid(m_axi_arvalid),
        .S_AXI_awaddr(m_axi_awaddr),
        .S_AXI_awburst(m_axi_awburst),
        .S_AXI_awid('d0),
        .S_AXI_awcache('d0),
        .S_AXI_awlen(m_axi_awlen),
        .S_AXI_awlock('d0),
        .S_AXI_awprot('d0),
        .S_AXI_awqos('d0),
        .S_AXI_awready(m_axi_awready),
        .S_AXI_awregion('d0),
        .S_AXI_awsize(m_axi_awsize),
        .S_AXI_awvalid(m_axi_awvalid),
        .S_AXI_bready(m_axi_bready),
        .S_AXI_bresp(m_axi_bresp),
        .S_AXI_bvalid(m_axi_bvalid),
        .S_AXI_rdata(m_axi_rdata),
        .S_AXI_rlast(m_axi_rlast),
        .S_AXI_rready(m_axi_rready),
        .S_AXI_rresp(m_axi_rresp),
        .S_AXI_rvalid(m_axi_rvalid),
        .S_AXI_wdata(m_axi_wdata),
        .S_AXI_wlast(m_axi_wlast),
        .S_AXI_wready(m_axi_wready),
        .S_AXI_wstrb(m_axi_wstrb),
        .S_AXI_wvalid(m_axi_wvalid),
        .aclk(ap_clk),
        .aresetn(ap_rstn ));
        
    // Reset Task
    task reset();
    begin
        ap_clk = 1'b0;
        ap_rstn = 1'b1;
        
         // Control signals
        s_axi_control_awvalid = 1'b0;
        s_axi_control_awaddr = 'h0;
        s_axi_control_wvalid = 1'b0;
        s_axi_control_wdata = 'h0;
        s_axi_control_wstrb = 'h0;
        s_axi_control_arvalid = 1'b0;
        s_axi_control_araddr = 'h0;
        s_axi_control_rready = 1'b0;
        s_axi_control_bready = 1'b0;
          

        
        
        #6;
        ap_rstn = 1'b0;
        #10;
        ap_rstn = 1'b1;
    end
    endtask

    
 
task axi_write_request(input [31:0] addr);
begin


    #0
    s_axi_control_awvalid = 1'b1;
    s_axi_control_awaddr  = addr;
    
    
    @(posedge ap_clk);

    
    while (s_axi_control_awready == 1'b0) begin
        @(posedge ap_clk);
    end

    #0
    s_axi_control_awvalid = 1'b0;
    s_axi_control_awaddr  = 'h0;
end    
        
endtask    


task axi_write_data(input [255:0] data);
begin

  
    #0
    s_axi_control_wvalid = 1'b1;
    s_axi_control_wstrb = 4'b1111;
    s_axi_control_wdata  = data;
    
      @(posedge ap_clk);
        
    while( s_axi_control_wready == 1'b0) begin
        @(posedge ap_clk);
    end                   
    
    #0
     s_axi_control_wvalid = 1'b0;
        s_axi_control_wstrb = 4'b0;
        s_axi_control_wdata  = 'h0;
                                                                
        
   
end
endtask    
        

task axi_write_response ();
begin
    #0
    s_axi_control_bready = 1'b1;
    
      @(posedge ap_clk);
    
    while( s_axi_control_bvalid == 1'b0) begin
        @(posedge ap_clk);
      
    end    
   #0
    s_axi_control_bready = 1'b0;  
      
        
   
end
endtask    
        

task axi_write_ch (input [31:0] addr, [255:0] data);
begin

axi_write_request(addr);
axi_write_data(data);
axi_write_response();   
   
end
endtask    

task axi_read_request(input [31:0] addr);
begin

    #0
    s_axi_control_arvalid = 1'b1;
    s_axi_control_araddr  = addr;

      @(posedge ap_clk);
    
    while (s_axi_control_arready == 1'b0) begin
        @(posedge ap_clk);
    end

    #0
    s_axi_control_arvalid = 1'b0;
    s_axi_control_araddr  = 'h0;
end    
        
endtask    


task axi_read_data( output logic [255:0] read_data);
begin

 
    #0
    s_axi_control_rready = 1'b1;

      @(posedge ap_clk);

    while( s_axi_control_rvalid == 1'b0) begin
        @(posedge ap_clk);
        
 
    end            
    #0                                                                   
        read_data = s_axi_control_rdata;
         s_axi_control_rready = 1'b0;
   
end
endtask    
        

task axi_read_ch (input [31:0] addr, output logic [255:0] read_data);
begin

axi_read_request(addr);
axi_read_data(read_data);
   
   
end
endtask            
    
    
localparam BYTE_LEN = 4*`DATA_SIZE;    
    
logic [31:0] read_data;   
logic [31:0] krnl_done;     
    
always #5 ap_clk = ~ap_clk;

initial begin

reset();
@(posedge ap_clk);


axi_write_ch(`ADDR_BYTE_LEN_DATA, BYTE_LEN );
axi_write_ch(`ADDR_SRC_DATA, `SRC_ADDR );
axi_write_ch(`ADDR_DST_DATA, `DST_ADDR );
axi_write_ch(`ADDR_USER_CTRL, `START );

read_data = 32'b0;
krnl_done = 32'b0;


while ( krnl_done != `DONE) begin


axi_read_ch(`ADDR_USER_CTRL, read_data ); 
krnl_done = read_data & (32'hffff_fff2) ;
    
end

$display ("DMA transfer done !! " );

$finish;



end
    


    

    
endmodule



