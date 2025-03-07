
`timescale 1ns/1ps

module s_axi_control
#(parameter
    C_S_AXI_ADDR_WIDTH = 6,
    C_S_AXI_DATA_WIDTH = 32
)(
    input  wire                          ACLK,
    input  wire                          ARESET,
    input  wire                          ACLK_EN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] AWADDR,
    input  wire                          AWVALID,
    output wire                          AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] WDATA,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0] WSTRB,
    input  wire                          WVALID,
    output wire                          WREADY,
    output wire [1:0]                    BRESP,
    output wire                          BVALID,
    input  wire                          BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] ARADDR,
    input  wire                          ARVALID,
    output wire                          ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] RDATA,
    output wire [1:0]                    RRESP,
    output wire                          RVALID,
    input  wire                          RREADY,
    
    output wire                          user_start,
    input  wire                          user_done,
    input  wire                          user_idle,
    output wire [31:0]                   byte_len,
    output wire [31:0]                   src_addr,
    output wire [31:0]                   dst_addr
);
//------------------------Address Info-------------------

// 0x10 : User Control signals
//        bit 0  - user_start (Read/Write/COH)
//        bit 1  - user_done (Read/COR)
//        bit 2  - user_idle (Read)
// 0x14 : Data signal of byte length
//        bit 31~0 - byte_len[31:0] (Read/Write)
// 0x18 : Data signal of src_addr
//        bit 31~0 - src_addr[31:0] (Read/Write)
// 0x1c : Data signal of dst_addr
//        bit 31~0 - dst_addr[31:0] (Read/Write)

// (SC = Self Clear, COR = Clear on Read, TOW = Toggle on Write, COH = Clear on Handshake)

//------------------------Parameter----------------------
localparam
    ADDR_USER_CTRL       = 6'h10,
    ADDR_BYTE_LEN_DATA   = 6'h14,
    ADDR_SRC_DATA        = 6'h18,
    ADDR_DST_DATA        = 6'h1c,


    WRIDLE               = 2'd0,
    WRDATA               = 2'd1,
    WRRESP               = 2'd2,
    WRRESET              = 2'd3,
    RDIDLE               = 2'd0,
    RDDATA               = 2'd1,
    RDRESET              = 2'd2,
    ADDR_BITS         = 6;

//------------------------Local signal-------------------
    reg  [1:0]                    wstate;
    reg  [1:0]                    wnext;
    reg  [ADDR_BITS-1:0]          waddr;
    wire [31:0]                   wmask;
    wire                          aw_hs;
    wire                          w_hs;
    reg  [1:0]                    rstate;
    reg  [1:0]                    rnext;
    reg  [31:0]                   rdata;
    wire                          ar_hs;
    wire [ADDR_BITS-1:0]          raddr;
    // internal registers
    reg                           int_ap_idle;
    reg                           int_ap_ready;
    reg                           int_ap_done = 1'b0;
    reg                           int_ap_start = 1'b0;

    reg  [31:0]                   byte_len_reg = 'b0;
    reg  [31:0]                   src_addr_reg = 'b0;
    reg  [31:0]                   dst_addr_reg = 'b0;

//------------------------Instantiation------------------

//------------------------AXI write fsm------------------
assign AWREADY = (wstate == WRIDLE);
assign WREADY  = (wstate == WRDATA);
assign BRESP   = 2'b00;  // OKAY
assign BVALID  = (wstate == WRRESP);
assign wmask   = { {8{WSTRB[3]}}, {8{WSTRB[2]}}, {8{WSTRB[1]}}, {8{WSTRB[0]}} };
assign aw_hs   = AWVALID & AWREADY;
assign w_hs    = WVALID & WREADY;

// wstate
always @(posedge ACLK) begin
    if (ARESET)
        wstate <= WRIDLE;
    else if (ACLK_EN)
        wstate <= wnext;
end

// wnext
always @(*) begin
    case (wstate)
        WRIDLE:
            if (AWVALID)
                wnext = WRDATA;
            else
                wnext = WRIDLE;
        WRDATA:
            if (WVALID)
                wnext = WRRESP;
            else
                wnext = WRDATA;
        WRRESP:
            if (BREADY)
                wnext = WRIDLE;
            else
                wnext = WRRESP;
        default:
            wnext = WRIDLE;
    endcase
end

// waddr
always @(posedge ACLK) begin
    if(ARESET) 
        waddr <=0;
    
    else if (ACLK_EN) begin
        if (aw_hs)
            waddr <= AWADDR[ADDR_BITS-1:0];
    end
end

//------------------------AXI read fsm-------------------
assign ARREADY = (rstate == RDIDLE);
assign RDATA   = rdata;
assign RRESP   = 2'b00;  // OKAY
assign RVALID  = (rstate == RDDATA);
assign ar_hs   = ARVALID & ARREADY;
assign raddr   = ARADDR[ADDR_BITS-1:0];

// rstate
always @(posedge ACLK) begin
    if (ARESET)
        rstate <= RDIDLE;
    else if (ACLK_EN)
        rstate <= rnext;
end

// rnext
always @(*) begin
    case (rstate)
        RDIDLE:
            if (ARVALID)
                rnext = RDDATA;
            else
                rnext = RDIDLE;
        RDDATA:
            if (RREADY & RVALID)
                rnext = RDIDLE;
            else
                rnext = RDDATA;
        default:
            rnext = RDIDLE;
    endcase
end

// rdata
always @(posedge ACLK) begin
    if (ARESET) rdata <= 32'b0;
    
    else if (ACLK_EN) begin
        if (ar_hs) begin
            case (raddr)
                ADDR_USER_CTRL: begin
                    rdata[0] <= int_ap_start;
                    rdata[1] <= int_ap_done;
                    rdata[2] <= int_ap_idle;
                end
                
                ADDR_BYTE_LEN_DATA: begin
                    rdata <= byte_len_reg;
                end
                ADDR_SRC_DATA: begin
                    rdata <= src_addr_reg;
                end

                ADDR_DST_DATA: begin
                    rdata <= dst_addr_reg;
                end

            endcase
        end
    end
end


//------------------------Register logic-----------------
assign user_start  = int_ap_start;
assign byte_len = byte_len_reg;
assign src_addr    = src_addr_reg;
assign dst_addr    = dst_addr_reg;
// int_ap_start
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_start <= 1'b0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_USER_CTRL && WSTRB[0] && WDATA[0])
            int_ap_start <= 1'b1;
        else if (user_done)
            int_ap_start <= 1'b0; // clear on handshake/auto restart
    end
end

// int_ap_done
always @(posedge ACLK) begin
    if (ARESET)
        int_ap_done <= 1'b0;
    else if (ACLK_EN) begin
    
        if (user_done)
            int_ap_done <= 1'b1;
        else if (ar_hs && raddr == ADDR_USER_CTRL)
            int_ap_done <= 1'b0; // clear on read
    end
end

//int_ap_idle

always @(posedge ACLK) begin
    if (ARESET)
        int_ap_idle <= 1'b0;
    else if (ACLK_EN) begin
            int_ap_idle <= user_idle;
    end
end


// byte_len_reg 
always @(posedge ACLK) begin
    if (ARESET)
        byte_len_reg <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_BYTE_LEN_DATA)
            byte_len_reg <= (WDATA & wmask) | (byte_len_reg & ~wmask);
    end
end

// src_addr_reg
always @(posedge ACLK) begin
    if (ARESET)
        src_addr_reg <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_SRC_DATA)
            src_addr_reg <= (WDATA & wmask) | (src_addr_reg & ~wmask);
    end
end

// dst_addr_reg
always @(posedge ACLK) begin
    if (ARESET)
        dst_addr_reg <= 0;
    else if (ACLK_EN) begin
        if (w_hs && waddr == ADDR_DST_DATA)
            dst_addr_reg <= (WDATA & wmask) | (dst_addr_reg & ~wmask);
    end
end


//------------------------Memory logic-------------------

endmodule