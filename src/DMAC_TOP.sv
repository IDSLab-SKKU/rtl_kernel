
`timescale 1ns / 1ps



module DMAC_TOP #(
  parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12 ,
  parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32
)(
    //AXI lite interface
      // AXI4-Lite slave interface

    input  wire                                    ap_clk,
    input  wire                                    ap_rstn,
    input  wire                                    s_axi_control_awvalid,
    output wire                                    s_axi_control_awready,
    input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_awaddr ,
    input  wire                                    s_axi_control_wvalid ,
    output wire                                    s_axi_control_wready ,
    input  wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_wdata  ,
    input  wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb  ,
    input  wire                                    s_axi_control_arvalid,
    output wire                                    s_axi_control_arready,
    input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_araddr ,
    output wire                                    s_axi_control_rvalid ,
    input  wire                                    s_axi_control_rready ,
    output wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_rdata  ,
    output wire [2-1:0]                            s_axi_control_rresp  ,
    output wire                                    s_axi_control_bvalid ,
    input  wire                                    s_axi_control_bready ,
    output wire [2-1:0]                            s_axi_control_bresp  ,
    


    // AMBA AXI interface (AW channel)
    output  wire    [3:0]       m_axi_awid,
    output  wire    [31:0]      m_axi_awaddr,
    output  wire    [7:0]       m_axi_awlen,
    output  wire    [2:0]       m_axi_awsize,
    output  wire    [1:0]       m_axi_awburst,
    output  wire                m_axi_awvalid,
    input   wire                m_axi_awready,
    output  wire                m_axi_awlock,
    output  wire    [3:0]       m_axi_awcache,
    output  wire    [2:0]       m_axi_awprot,
    output  wire    [3:0]       m_axi_awqos,
    output  wire    [3:0]       m_axi_awregion,
    
    // AMBA AXI interface (W channel)
    output  wire    [255:0]      m_axi_wdata,
    output  wire    [31:0]       m_axi_wstrb,
    output  wire                m_axi_wlast,
    output  wire                m_axi_wvalid,
    input   wire                m_axi_wready,

    // AMBA AXI interface (B channel)
    input   wire    [3:0]       m_axi_bid,
    input   wire    [1:0]       m_axi_bresp,
    input   wire                m_axi_bvalid,
    output  wire                m_axi_bready,

    // AMBA AXI interface (AR channel)
    output  wire    [3:0]       m_axi_arid,
    output  wire    [31:0]      m_axi_araddr,
    output  wire    [7:0]       m_axi_arlen,
    output  wire    [2:0]       m_axi_arsize,
    output  wire    [1:0]       m_axi_arburst,
    output  wire                m_axi_arvalid,
    input   wire                m_axi_arready,
    output  wire                m_axi_arlock,
    output  wire    [3:0]       m_axi_arcache,
    output  wire    [2:0]       m_axi_arprot,
    output  wire    [3:0]       m_axi_arqos,
    output  wire    [3:0]       m_axi_arregion,

    // AMBA AXI interface (R channel)
    input   wire    [3:0]       m_axi_rid,
    input   wire    [255:0]      m_axi_rdata,
    input   wire    [1:0]       m_axi_rresp,
    input   wire                m_axi_rlast,
    input   wire                m_axi_rvalid,
    output  wire                m_axi_rready
);

    wire                        user_start,
                                user_done,
                                user_idle;
    wire    [31:0]              src_addr,
                                dst_addr;
    wire    [31:0]              byte_len;

    assign m_axi_awlock    = 1'b0;
    assign m_axi_awcache   = 4'd0;
    assign m_axi_awprot    = 3'd0;
    assign m_axi_awqos     = 4'd0;
    assign m_axi_awregion  = 4'd0;
    
    assign m_axi_arlock    = 1'b0;
    assign m_axi_arcache   = 4'd0;
    assign m_axi_arprot    = 3'd0;
    assign m_axi_arqos     = 4'd0;
    assign m_axi_arregion  = 4'd0;

    assign m_axi_awid = 'd0;
    assign m_axi_arid = 'd0;
    
            s_axi_control #(
            .C_S_AXI_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
            .C_S_AXI_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
            )
            inst_control_s_axi (
            .ACLK      ( ap_clk                ),
            .ARESET    ( !ap_rstn                ),
            .ACLK_EN   ( 1'b1                  ),
            .AWVALID   ( s_axi_control_awvalid ),
            .AWREADY   ( s_axi_control_awready ),
            .AWADDR    ( s_axi_control_awaddr  ),
            .WVALID    ( s_axi_control_wvalid  ),
            .WREADY    ( s_axi_control_wready  ),
            .WDATA     ( s_axi_control_wdata   ),
            .WSTRB     ( s_axi_control_wstrb   ),
            .ARVALID   ( s_axi_control_arvalid ),
            .ARREADY   ( s_axi_control_arready ),
            .ARADDR    ( s_axi_control_araddr  ),
            .RVALID    ( s_axi_control_rvalid  ),
            .RREADY    ( s_axi_control_rready  ),
            .RDATA     ( s_axi_control_rdata   ),
            .RRESP     ( s_axi_control_rresp   ),
            .BVALID    ( s_axi_control_bvalid  ),
            .BREADY    ( s_axi_control_bready  ),
            .BRESP     ( s_axi_control_bresp   ),
            .user_start( user_start            ),
            .user_done ( user_done             ),
            .user_idle ( user_idle             ),
            .byte_len  ( byte_len              ),
            .src_addr  ( src_addr              ),
            .dst_addr  ( dst_addr              )
            );

            DMAC_ENGINE u_engine(
                .clk                    (ap_clk),
                .rst_n                  (ap_rstn),
        
                // configuration registers
                .src_addr_i             (src_addr),
                .dst_addr_i             (dst_addr),
                .byte_len_i             (byte_len),
                .start_i                (user_start),
                .done_o                 (user_done),
                .idle_o                 (user_idle),
        
                // AMBA AXI interface (AW channel)
                .awaddr_o               (m_axi_awaddr),
                .awlen_o                (m_axi_awlen),
                .awsize_o               (m_axi_awsize),
                .awburst_o              (m_axi_awburst),
                .awvalid_o              (m_axi_awvalid),
                .awready_i              (m_axi_awready),
        
                // AMBA AXI interface (W channel)
                .wdata_o                (m_axi_wdata),
                .wstrb_o                (m_axi_wstrb),
                .wlast_o                (m_axi_wlast),
                .wvalid_o               (m_axi_wvalid),
                .wready_i               (m_axi_wready),
        
                // AMBA AXI interface (B channel)
                .bresp_i                (m_axi_bresp),
                .bvalid_i               (m_axi_bvalid),
                .bready_o               (m_axi_bready),
        
                // AMBA AXI interface (AR channel)
                .araddr_o               (m_axi_araddr),
                .arlen_o                (m_axi_arlen),
                .arsize_o               (m_axi_arsize),
                .arburst_o              (m_axi_arburst),
                .arvalid_o              (m_axi_arvalid),
                .arready_i              (m_axi_arready),
        
                // AMBA AXI interface (R channel)
                .rdata_i                (m_axi_rdata),
                .rresp_i                (m_axi_rresp),
                .rlast_i                (m_axi_rlast),
                .rvalid_i               (m_axi_rvalid),
                .rready_o               (m_axi_rready)
            );

    
        

endmodule
