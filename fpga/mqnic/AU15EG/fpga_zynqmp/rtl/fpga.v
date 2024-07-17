// SPDX-License-Identifier: BSD-2-Clause-Views
/*
 * Copyright (c) 2019-2023 The Regents of the University of California
 * Copyright (c) 2021-2023 MissingLinkElectronics Inc.
 */

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA top-level module
 */
module fpga #
(
    // FW and board IDs
    parameter FPGA_ID = 32'h4750093,
    parameter FW_ID = 32'h00000000,
    parameter FW_VER = 32'h00_00_01_00,
    parameter BOARD_ID = 32'h10ee_906a,
    parameter BOARD_VER = 32'h01_00_00_00,
    parameter BUILD_DATE = 32'd602976000,
    parameter GIT_HASH = 32'hdce357bf,
    parameter RELEASE_INFO = 32'h00000000,

    // Board configuration
    parameter TDMA_BER_ENABLE = 0,

    // Structural configuration
    parameter IF_COUNT = 2,
    parameter PORTS_PER_IF = 1,
    parameter SCHED_PER_IF = PORTS_PER_IF,
    parameter PORT_MASK = 0,

    // Clock configuration
    parameter CLK_PERIOD_NS_NUM = 8,
    parameter CLK_PERIOD_NS_DENOM = 1,

    // PTP configuration
    parameter PTP_CLOCK_PIPELINE = 0,
    parameter PTP_CLOCK_CDC_PIPELINE = 0,
    parameter PTP_PORT_CDC_PIPELINE = 0,
    parameter PTP_PEROUT_ENABLE = 1,
    parameter PTP_PEROUT_COUNT = 1,

    // Queue manager configuration
    parameter EVENT_QUEUE_OP_TABLE_SIZE = 4,
    parameter TX_QUEUE_OP_TABLE_SIZE = 4,
    parameter RX_QUEUE_OP_TABLE_SIZE = 4,
    parameter CQ_OP_TABLE_SIZE = 4,
    parameter EQN_WIDTH = 2,
    parameter TX_QUEUE_INDEX_WIDTH = 2,
    parameter RX_QUEUE_INDEX_WIDTH = 2,
    parameter CQN_WIDTH = (TX_QUEUE_INDEX_WIDTH > RX_QUEUE_INDEX_WIDTH ? TX_QUEUE_INDEX_WIDTH : RX_QUEUE_INDEX_WIDTH) + 1,
    parameter EQ_PIPELINE = 3,
    parameter TX_QUEUE_PIPELINE = 3+(TX_QUEUE_INDEX_WIDTH > 12 ? TX_QUEUE_INDEX_WIDTH-12 : 0),
    parameter RX_QUEUE_PIPELINE = 3+(RX_QUEUE_INDEX_WIDTH > 12 ? RX_QUEUE_INDEX_WIDTH-12 : 0),
    parameter CQ_PIPELINE = 3+(CQN_WIDTH > 12 ? CQN_WIDTH-12 : 0),

    // TX and RX engine configuration
    parameter TX_DESC_TABLE_SIZE = 32,
    parameter RX_DESC_TABLE_SIZE = 32,
    parameter RX_INDIR_TBL_ADDR_WIDTH = RX_QUEUE_INDEX_WIDTH > 8 ? 8 : RX_QUEUE_INDEX_WIDTH,

    // Scheduler configuration
    parameter TX_SCHEDULER_OP_TABLE_SIZE = TX_DESC_TABLE_SIZE,
    parameter TX_SCHEDULER_PIPELINE = TX_QUEUE_PIPELINE,
    parameter TDMA_INDEX_WIDTH = 6,

    // Interface configuration
    parameter PTP_TS_ENABLE = 0,
    parameter TX_CPL_FIFO_DEPTH = 32,
    parameter TX_CHECKSUM_ENABLE = 1,
    parameter RX_HASH_ENABLE = 1,
    parameter RX_CHECKSUM_ENABLE = 1,
    parameter PFC_ENABLE = 1,
    parameter LFC_ENABLE = PFC_ENABLE,
    parameter ENABLE_PADDING = 1,
    parameter ENABLE_DIC = 1,
    parameter MIN_FRAME_LENGTH = 64,
    parameter TX_FIFO_DEPTH = 32768,
    parameter RX_FIFO_DEPTH = 32768,
    parameter MAX_TX_SIZE = 9214,
    parameter MAX_RX_SIZE = 9214,
    parameter TX_RAM_SIZE = 32768,
    parameter RX_RAM_SIZE = 32768,

    // RAM configuration
    parameter DDR_CH = 1,
    parameter DDR_ENABLE = 0,
    parameter AXI_DDR_DATA_WIDTH = 512,
    parameter AXI_DDR_ADDR_WIDTH = 31,
    parameter AXI_DDR_ID_WIDTH = 8,
    parameter AXI_DDR_MAX_BURST_LEN = 256,
    parameter AXI_DDR_NARROW_BURST = 0,

    // Application block configuration
    parameter APP_ID = 32'h00000000,
    parameter APP_ENABLE = 0,
    parameter APP_CTRL_ENABLE = 1,
    parameter APP_DMA_ENABLE = 1,
    parameter APP_AXIS_DIRECT_ENABLE = 1,
    parameter APP_AXIS_SYNC_ENABLE = 1,
    parameter APP_AXIS_IF_ENABLE = 1,
    parameter APP_STAT_ENABLE = 1,

    // AXI interface configuration (DMA)
    parameter AXI_DATA_WIDTH = 128,
    parameter AXI_ADDR_WIDTH = 64,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    parameter AXI_ID_WIDTH = 6,

    // DMA interface configuration
    parameter DMA_IMM_ENABLE = 0,
    parameter DMA_IMM_WIDTH = 32,
    parameter DMA_LEN_WIDTH = 16,
    parameter DMA_TAG_WIDTH = 16,
    parameter RAM_ADDR_WIDTH = $clog2(TX_RAM_SIZE > RX_RAM_SIZE ? TX_RAM_SIZE : RX_RAM_SIZE),
    parameter RAM_PIPELINE = 2,
    parameter AXI_DMA_MAX_BURST_LEN = 16,

    // Interrupts
    parameter IRQ_COUNT = 8,
    parameter IRQ_STRETCH = 10,

    // AXI lite interface configuration (control)
    parameter AXIL_CTRL_DATA_WIDTH = 32,
    parameter AXIL_CTRL_ADDR_WIDTH = 24,
    parameter AXIL_CTRL_STRB_WIDTH = (AXIL_CTRL_DATA_WIDTH/8),

    // AXI lite interface configuration (application control)
    parameter AXIL_APP_CTRL_DATA_WIDTH = AXIL_CTRL_DATA_WIDTH,
    parameter AXIL_APP_CTRL_ADDR_WIDTH = 24,
    parameter AXIL_APP_CTRL_STRB_WIDTH = (AXIL_APP_CTRL_DATA_WIDTH/8),

    // Ethernet interface configuration
    parameter AXIS_ETH_TX_PIPELINE = 0,
    parameter AXIS_ETH_TX_FIFO_PIPELINE = 2,
    parameter AXIS_ETH_TX_TS_PIPELINE = 0,
    parameter AXIS_ETH_RX_PIPELINE = 0,
    parameter AXIS_ETH_RX_FIFO_PIPELINE = 2,

    // Statistics counter subsystem
    parameter STAT_ENABLE = 1,
    parameter STAT_DMA_ENABLE = 1,
    parameter STAT_AXI_ENABLE = 1,
    parameter STAT_INC_WIDTH = 24,
    parameter STAT_ID_WIDTH = 12
)
(
    /*
     * LEDs
     */
    output wire [1:0]   led
);

// PTP configuration
parameter PTP_CLK_PERIOD_NS_NUM = 8;
parameter PTP_CLK_PERIOD_NS_DENOM = 1;
parameter PTP_TS_WIDTH = 96;
parameter IF_PTP_PERIOD_NS = 6'h6;
parameter IF_PTP_PERIOD_FNS = 16'h6666;

// Interface configuration
parameter TX_TAG_WIDTH = 16;

// RAM configuration
parameter AXI_DDR_STRB_WIDTH = (AXI_DDR_DATA_WIDTH/8);

// Ethernet interface configuration
parameter XGMII_DATA_WIDTH = 64;
parameter XGMII_CTRL_WIDTH = XGMII_DATA_WIDTH/8;
parameter AXIS_ETH_DATA_WIDTH = XGMII_DATA_WIDTH;
parameter AXIS_ETH_KEEP_WIDTH = AXIS_ETH_DATA_WIDTH/8;
parameter AXIS_ETH_SYNC_DATA_WIDTH = AXIS_ETH_DATA_WIDTH;
parameter AXIS_ETH_TX_USER_WIDTH = TX_TAG_WIDTH + 1;
parameter AXIS_ETH_RX_USER_WIDTH = (PTP_TS_ENABLE ? PTP_TS_WIDTH : 0) + 1;

// Clock and reset
wire zynq_pl_clk;
wire zynq_pl_reset;

// Internal 125 MHz clock
wire clk_125mhz_int;
wire rst_125mhz_int;

sync_reset #(
    .N(4)
)
sync_reset_125mhz_inst (
    .clk(clk_125mhz_int),
    .rst(zynq_pl_reset),
    .out(rst_125mhz_int)
);

// Zynq AXI MM
wire [IRQ_COUNT-1:0]                 irq;

wire [AXI_ID_WIDTH-1:0]              axi_awid;
wire [AXI_ADDR_WIDTH-1:0]            axi_awaddr;
wire [7:0]                           axi_awlen;
wire [2:0]                           axi_awsize;
wire [1:0]                           axi_awburst;
wire                                 axi_awlock;
wire [3:0]                           axi_awcache;
wire [2:0]                           axi_awprot;
wire                                 axi_awvalid;
wire                                 axi_awready;
wire [AXI_DATA_WIDTH-1:0]            axi_wdata;
wire [AXI_STRB_WIDTH-1:0]            axi_wstrb;
wire                                 axi_wlast;
wire                                 axi_wvalid;
wire                                 axi_wready;
wire [AXI_ID_WIDTH-1:0]              axi_bid;
wire [1:0]                           axi_bresp;
wire                                 axi_bvalid;
wire                                 axi_bready;
wire [AXI_ID_WIDTH-1:0]              axi_arid;
wire [AXI_ADDR_WIDTH-1:0]            axi_araddr;
wire [7:0]                           axi_arlen;
wire [2:0]                           axi_arsize;
wire [1:0]                           axi_arburst;
wire                                 axi_arlock;
wire [3:0]                           axi_arcache;
wire [2:0]                           axi_arprot;
wire                                 axi_arvalid;
wire                                 axi_arready;
wire [AXI_ID_WIDTH-1:0]              axi_rid;
wire [AXI_DATA_WIDTH-1:0]            axi_rdata;
wire [1:0]                           axi_rresp;
wire                                 axi_rlast;
wire                                 axi_rvalid;
wire                                 axi_rready;

// AXI lite connections
wire [AXIL_CTRL_ADDR_WIDTH-1:0]      axil_ctrl_awaddr;
wire [2:0]                           axil_ctrl_awprot;
wire                                 axil_ctrl_awvalid;
wire                                 axil_ctrl_awready;
wire [AXIL_CTRL_DATA_WIDTH-1:0]      axil_ctrl_wdata;
wire [AXIL_CTRL_STRB_WIDTH-1:0]      axil_ctrl_wstrb;
wire                                 axil_ctrl_wvalid;
wire                                 axil_ctrl_wready;
wire [1:0]                           axil_ctrl_bresp;
wire                                 axil_ctrl_bvalid;
wire                                 axil_ctrl_bready;
wire [AXIL_CTRL_ADDR_WIDTH-1:0]      axil_ctrl_araddr;
wire [2:0]                           axil_ctrl_arprot;
wire                                 axil_ctrl_arvalid;
wire                                 axil_ctrl_arready;
wire [AXIL_CTRL_DATA_WIDTH-1:0]      axil_ctrl_rdata;
wire [1:0]                           axil_ctrl_rresp;
wire                                 axil_ctrl_rvalid;
wire                                 axil_ctrl_rready;

wire [AXIL_APP_CTRL_ADDR_WIDTH-1:0]  axil_app_ctrl_awaddr;
wire [2:0]                           axil_app_ctrl_awprot;
wire                                 axil_app_ctrl_awvalid;
wire                                 axil_app_ctrl_awready;
wire [AXIL_APP_CTRL_DATA_WIDTH-1:0]  axil_app_ctrl_wdata;
wire [AXIL_APP_CTRL_STRB_WIDTH-1:0]  axil_app_ctrl_wstrb;
wire                                 axil_app_ctrl_wvalid;
wire                                 axil_app_ctrl_wready;
wire [1:0]                           axil_app_ctrl_bresp;
wire                                 axil_app_ctrl_bvalid;
wire                                 axil_app_ctrl_bready;
wire [AXIL_APP_CTRL_ADDR_WIDTH-1:0]  axil_app_ctrl_araddr;
wire [2:0]                           axil_app_ctrl_arprot;
wire                                 axil_app_ctrl_arvalid;
wire                                 axil_app_ctrl_arready;
wire [AXIL_APP_CTRL_DATA_WIDTH-1:0]  axil_app_ctrl_rdata;
wire [1:0]                           axil_app_ctrl_rresp;
wire                                 axil_app_ctrl_rvalid;
wire                                 axil_app_ctrl_rready;

reg [(IRQ_COUNT*IRQ_STRETCH)-1:0] irq_stretch = {(IRQ_COUNT*IRQ_STRETCH){1'b0}};
always @(posedge zynq_pl_clk) begin
    if (zynq_pl_reset) begin
        irq_stretch <= {(IRQ_COUNT*IRQ_STRETCH){1'b0}};
    end else begin
        /* IRQ shift vector */
        irq_stretch <= {irq_stretch[0 +: (IRQ_COUNT*IRQ_STRETCH)-IRQ_COUNT], irq};
    end
end

reg [IRQ_COUNT-1:0] zynq_irq;
integer i, k;
always @* begin
    for (k = 0; k < IRQ_COUNT; k = k + 1) begin
        zynq_irq[k] = 1'b0;
        for (i = 0; i < (IRQ_COUNT*IRQ_STRETCH); i = i + IRQ_COUNT) begin
            zynq_irq[k] = zynq_irq[k] | irq_stretch[k + i];
        end
    end
end

zynq_ps zynq_ps_inst (
    .pl_clk_125(clk_125mhz_int),
    .pl_clk0(zynq_pl_clk),
    .pl_reset(zynq_pl_reset),

    .pl_ps_irq0(zynq_irq),

    .m_axil_ctrl_araddr(axil_ctrl_araddr),
    .m_axil_ctrl_arprot(axil_ctrl_arprot),
    .m_axil_ctrl_arready(axil_ctrl_arready),
    .m_axil_ctrl_arvalid(axil_ctrl_arvalid),
    .m_axil_ctrl_awaddr(axil_ctrl_awaddr),
    .m_axil_ctrl_awprot(axil_ctrl_awprot),
    .m_axil_ctrl_awready(axil_ctrl_awready),
    .m_axil_ctrl_awvalid(axil_ctrl_awvalid),
    .m_axil_ctrl_bready(axil_ctrl_bready),
    .m_axil_ctrl_bresp(axil_ctrl_bresp),
    .m_axil_ctrl_bvalid(axil_ctrl_bvalid),
    .m_axil_ctrl_rdata(axil_ctrl_rdata),
    .m_axil_ctrl_rready(axil_ctrl_rready),
    .m_axil_ctrl_rresp(axil_ctrl_rresp),
    .m_axil_ctrl_rvalid(axil_ctrl_rvalid),
    .m_axil_ctrl_wdata(axil_ctrl_wdata),
    .m_axil_ctrl_wready(axil_ctrl_wready),
    .m_axil_ctrl_wstrb(axil_ctrl_wstrb),
    .m_axil_ctrl_wvalid(axil_ctrl_wvalid),

    .m_axil_app_ctrl_araddr(axil_app_ctrl_araddr),
    .m_axil_app_ctrl_arprot(axil_app_ctrl_arprot),
    .m_axil_app_ctrl_arready(axil_app_ctrl_arready),
    .m_axil_app_ctrl_arvalid(axil_app_ctrl_arvalid),
    .m_axil_app_ctrl_awaddr(axil_app_ctrl_awaddr),
    .m_axil_app_ctrl_awprot(axil_app_ctrl_awprot),
    .m_axil_app_ctrl_awready(axil_app_ctrl_awready),
    .m_axil_app_ctrl_awvalid(axil_app_ctrl_awvalid),
    .m_axil_app_ctrl_bready(axil_app_ctrl_bready),
    .m_axil_app_ctrl_bresp(axil_app_ctrl_bresp),
    .m_axil_app_ctrl_bvalid(axil_app_ctrl_bvalid),
    .m_axil_app_ctrl_rdata(axil_app_ctrl_rdata),
    .m_axil_app_ctrl_rready(axil_app_ctrl_rready),
    .m_axil_app_ctrl_rresp(axil_app_ctrl_rresp),
    .m_axil_app_ctrl_rvalid(axil_app_ctrl_rvalid),
    .m_axil_app_ctrl_wdata(axil_app_ctrl_wdata),
    .m_axil_app_ctrl_wready(axil_app_ctrl_wready),
    .m_axil_app_ctrl_wstrb(axil_app_ctrl_wstrb),
    .m_axil_app_ctrl_wvalid(axil_app_ctrl_wvalid),

    .s_axi_dma_araddr(axi_araddr),
    .s_axi_dma_arburst(axi_arburst),
    .s_axi_dma_arcache(axi_arcache),
    .s_axi_dma_arid(axi_arid),
    .s_axi_dma_arlen(axi_arlen),
    .s_axi_dma_arlock(axi_arlock),
    .s_axi_dma_arprot(axi_arprot),
    .s_axi_dma_arqos({4{1'b0}}),
    .s_axi_dma_arready(axi_arready),
    .s_axi_dma_arsize(axi_arsize),
    .s_axi_dma_aruser(1'b0),
    .s_axi_dma_arvalid(axi_arvalid),
    .s_axi_dma_awaddr(axi_awaddr),
    .s_axi_dma_awburst(axi_awburst),
    .s_axi_dma_awcache(axi_awcache),
    .s_axi_dma_awid(axi_awid),
    .s_axi_dma_awlen(axi_awlen),
    .s_axi_dma_awlock(axi_awlock),
    .s_axi_dma_awprot(axi_awprot),
    .s_axi_dma_awqos({4{1'b0}}),
    .s_axi_dma_awready(axi_awready),
    .s_axi_dma_awsize(axi_awsize),
    .s_axi_dma_awuser(1'b0),
    .s_axi_dma_awvalid(axi_awvalid),
    .s_axi_dma_bid(axi_bid),
    .s_axi_dma_bready(axi_bready),
    .s_axi_dma_bresp(axi_bresp),
    .s_axi_dma_bvalid(axi_bvalid),
    .s_axi_dma_rdata(axi_rdata),
    .s_axi_dma_rid(axi_rid),
    .s_axi_dma_rlast(axi_rlast),
    .s_axi_dma_rready(axi_rready),
    .s_axi_dma_rresp(axi_rresp),
    .s_axi_dma_rvalid(axi_rvalid),
    .s_axi_dma_wdata(axi_wdata),
    .s_axi_dma_wlast(axi_wlast),
    .s_axi_dma_wready(axi_wready),
    .s_axi_dma_wstrb(axi_wstrb),
    .s_axi_dma_wvalid(axi_wvalid)
);

// DDR4
wire [DDR_CH-1:0]                     ddr_clk;
wire [DDR_CH-1:0]                     ddr_rst;

wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]    m_axi_ddr_awid;
wire [DDR_CH*AXI_DDR_ADDR_WIDTH-1:0]  m_axi_ddr_awaddr;
wire [DDR_CH*8-1:0]                   m_axi_ddr_awlen;
wire [DDR_CH*3-1:0]                   m_axi_ddr_awsize;
wire [DDR_CH*2-1:0]                   m_axi_ddr_awburst;
wire [DDR_CH-1:0]                     m_axi_ddr_awlock;
wire [DDR_CH*4-1:0]                   m_axi_ddr_awcache;
wire [DDR_CH*3-1:0]                   m_axi_ddr_awprot;
wire [DDR_CH*4-1:0]                   m_axi_ddr_awqos;
wire [DDR_CH-1:0]                     m_axi_ddr_awvalid;
wire [DDR_CH-1:0]                     m_axi_ddr_awready;
wire [DDR_CH*AXI_DDR_DATA_WIDTH-1:0]  m_axi_ddr_wdata;
wire [DDR_CH*AXI_DDR_STRB_WIDTH-1:0]  m_axi_ddr_wstrb;
wire [DDR_CH-1:0]                     m_axi_ddr_wlast;
wire [DDR_CH-1:0]                     m_axi_ddr_wvalid;
wire [DDR_CH-1:0]                     m_axi_ddr_wready;
wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]    m_axi_ddr_bid;
wire [DDR_CH*2-1:0]                   m_axi_ddr_bresp;
wire [DDR_CH-1:0]                     m_axi_ddr_bvalid;
wire [DDR_CH-1:0]                     m_axi_ddr_bready;
wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]    m_axi_ddr_arid;
wire [DDR_CH*AXI_DDR_ADDR_WIDTH-1:0]  m_axi_ddr_araddr;
wire [DDR_CH*8-1:0]                   m_axi_ddr_arlen;
wire [DDR_CH*3-1:0]                   m_axi_ddr_arsize;
wire [DDR_CH*2-1:0]                   m_axi_ddr_arburst;
wire [DDR_CH-1:0]                     m_axi_ddr_arlock;
wire [DDR_CH*4-1:0]                   m_axi_ddr_arcache;
wire [DDR_CH*3-1:0]                   m_axi_ddr_arprot;
wire [DDR_CH*4-1:0]                   m_axi_ddr_arqos;
wire [DDR_CH-1:0]                     m_axi_ddr_arvalid;
wire [DDR_CH-1:0]                     m_axi_ddr_arready;
wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]    m_axi_ddr_rid;
wire [DDR_CH*AXI_DDR_DATA_WIDTH-1:0]  m_axi_ddr_rdata;
wire [DDR_CH*2-1:0]                   m_axi_ddr_rresp;
wire [DDR_CH-1:0]                     m_axi_ddr_rlast;
wire [DDR_CH-1:0]                     m_axi_ddr_rvalid;
wire [DDR_CH-1:0]                     m_axi_ddr_rready;

wire [DDR_CH-1:0]                     ddr_status;

generate

if (DDR_ENABLE && DDR_CH > 0) begin

reg ddr4_rst_reg = 1'b1;

always @(posedge zynq_pl_clk or posedge zynq_pl_reset) begin
    if (zynq_pl_reset) begin
        ddr4_rst_reg <= 1'b1;
    end else begin
        ddr4_rst_reg <= 1'b0;
    end
end

ddr4_0 ddr4_inst (
    .c0_sys_clk_p(),
    .c0_sys_clk_n(),
    .sys_rst(ddr4_rst_reg),

    .c0_init_calib_complete(ddr_status[0 +: 1]),
    .dbg_clk(),
    .dbg_bus(),

    .c0_ddr4_adr(),
    .c0_ddr4_ba(),
    .c0_ddr4_cke(),
    .c0_ddr4_cs_n(),
    .c0_ddr4_dq(),
    .c0_ddr4_dqs_t(),
    .c0_ddr4_dqs_c(),
    .c0_ddr4_dm_dbi_n(),
    .c0_ddr4_odt(),
    .c0_ddr4_bg(),
    .c0_ddr4_reset_n(),
    .c0_ddr4_act_n(),
    .c0_ddr4_ck_t(),
    .c0_ddr4_ck_c(),

    .c0_ddr4_ui_clk(ddr_clk[0 +: 1]),
    .c0_ddr4_ui_clk_sync_rst(ddr_rst[0 +: 1]),

    .c0_ddr4_aresetn(!ddr_rst[0 +: 1]),

    .c0_ddr4_s_axi_awid(m_axi_ddr_awid[0*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_awaddr(m_axi_ddr_awaddr[0*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
    .c0_ddr4_s_axi_awlen(m_axi_ddr_awlen[0*8 +: 8]),
    .c0_ddr4_s_axi_awsize(m_axi_ddr_awsize[0*3 +: 3]),
    .c0_ddr4_s_axi_awburst(m_axi_ddr_awburst[0*2 +: 2]),
    .c0_ddr4_s_axi_awlock(m_axi_ddr_awlock[0 +: 1]),
    .c0_ddr4_s_axi_awcache(m_axi_ddr_awcache[0*4 +: 4]),
    .c0_ddr4_s_axi_awprot(m_axi_ddr_awprot[0*3 +: 3]),
    .c0_ddr4_s_axi_awqos(m_axi_ddr_awqos[0*4 +: 4]),
    .c0_ddr4_s_axi_awvalid(m_axi_ddr_awvalid[0 +: 1]),
    .c0_ddr4_s_axi_awready(m_axi_ddr_awready[0 +: 1]),
    .c0_ddr4_s_axi_wdata(m_axi_ddr_wdata[0*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH]),
    .c0_ddr4_s_axi_wstrb(m_axi_ddr_wstrb[0*AXI_DDR_STRB_WIDTH +: AXI_DDR_STRB_WIDTH]),
    .c0_ddr4_s_axi_wlast(m_axi_ddr_wlast[0 +: 1]),
    .c0_ddr4_s_axi_wvalid(m_axi_ddr_wvalid[0 +: 1]),
    .c0_ddr4_s_axi_wready(m_axi_ddr_wready[0 +: 1]),
    .c0_ddr4_s_axi_bready(m_axi_ddr_bready[0 +: 1]),
    .c0_ddr4_s_axi_bid(m_axi_ddr_bid[0*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_bresp(m_axi_ddr_bresp[0*2 +: 2]),
    .c0_ddr4_s_axi_bvalid(m_axi_ddr_bvalid[0 +: 1]),
    .c0_ddr4_s_axi_arid(m_axi_ddr_arid[0*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_araddr(m_axi_ddr_araddr[0*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
    .c0_ddr4_s_axi_arlen(m_axi_ddr_arlen[0*8 +: 8]),
    .c0_ddr4_s_axi_arsize(m_axi_ddr_arsize[0*3 +: 3]),
    .c0_ddr4_s_axi_arburst(m_axi_ddr_arburst[0*2 +: 2]),
    .c0_ddr4_s_axi_arlock(m_axi_ddr_arlock[0 +: 1]),
    .c0_ddr4_s_axi_arcache(m_axi_ddr_arcache[0*4 +: 4]),
    .c0_ddr4_s_axi_arprot(m_axi_ddr_arprot[0*3 +: 3]),
    .c0_ddr4_s_axi_arqos(m_axi_ddr_arqos[0*4 +: 4]),
    .c0_ddr4_s_axi_arvalid(m_axi_ddr_arvalid[0 +: 1]),
    .c0_ddr4_s_axi_arready(m_axi_ddr_arready[0 +: 1]),
    .c0_ddr4_s_axi_rready(m_axi_ddr_rready[0 +: 1]),
    .c0_ddr4_s_axi_rlast(m_axi_ddr_rlast[0 +: 1]),
    .c0_ddr4_s_axi_rvalid(m_axi_ddr_rvalid[0 +: 1]),
    .c0_ddr4_s_axi_rresp(m_axi_ddr_rresp[0*2 +: 2]),
    .c0_ddr4_s_axi_rid(m_axi_ddr_rid[0*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_rdata(m_axi_ddr_rdata[0*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH])
);

end else begin

assign ddr_clk = 0;
assign ddr_rst = 0;

assign m_axi_ddr_awready = 0;
assign m_axi_ddr_wready = 0;
assign m_axi_ddr_bid = 0;
assign m_axi_ddr_bresp = 0;
assign m_axi_ddr_bvalid = 0;
assign m_axi_ddr_arready = 0;
assign m_axi_ddr_rid = 0;
assign m_axi_ddr_rdata = 0;
assign m_axi_ddr_rresp = 0;
assign m_axi_ddr_rlast = 0;
assign m_axi_ddr_rvalid = 0;

assign ddr_status = 0;

end

endgenerate

fpga_core #(
    // FW and board IDs
    .FPGA_ID(FPGA_ID),
    .FW_ID(FW_ID),
    .FW_VER(FW_VER),
    .BOARD_ID(BOARD_ID),
    .BOARD_VER(BOARD_VER),
    .BUILD_DATE(BUILD_DATE),
    .GIT_HASH(GIT_HASH),
    .RELEASE_INFO(RELEASE_INFO),

    // Board configuration
    .TDMA_BER_ENABLE(TDMA_BER_ENABLE),

    // Structural configuration
    .IF_COUNT(IF_COUNT),
    .PORTS_PER_IF(PORTS_PER_IF),
    .SCHED_PER_IF(SCHED_PER_IF),
    .PORT_MASK(PORT_MASK),

    // Clock configuration
    .CLK_PERIOD_NS_NUM(CLK_PERIOD_NS_NUM),
    .CLK_PERIOD_NS_DENOM(CLK_PERIOD_NS_DENOM),

    // PTP configuration
    .PTP_CLK_PERIOD_NS_NUM(PTP_CLK_PERIOD_NS_NUM),
    .PTP_CLK_PERIOD_NS_DENOM(PTP_CLK_PERIOD_NS_DENOM),
    .PTP_TS_WIDTH(PTP_TS_WIDTH),
    .PTP_CLOCK_PIPELINE(PTP_CLOCK_PIPELINE),
    .PTP_CLOCK_CDC_PIPELINE(PTP_CLOCK_CDC_PIPELINE),
    .PTP_PORT_CDC_PIPELINE(PTP_PORT_CDC_PIPELINE),
    .PTP_PEROUT_ENABLE(PTP_PEROUT_ENABLE),
    .PTP_PEROUT_COUNT(PTP_PEROUT_COUNT),

    // Queue manager configuration
    .EVENT_QUEUE_OP_TABLE_SIZE(EVENT_QUEUE_OP_TABLE_SIZE),
    .TX_QUEUE_OP_TABLE_SIZE(TX_QUEUE_OP_TABLE_SIZE),
    .RX_QUEUE_OP_TABLE_SIZE(RX_QUEUE_OP_TABLE_SIZE),
    .CQ_OP_TABLE_SIZE(CQ_OP_TABLE_SIZE),
    .EQN_WIDTH(EQN_WIDTH),
    .TX_QUEUE_INDEX_WIDTH(TX_QUEUE_INDEX_WIDTH),
    .RX_QUEUE_INDEX_WIDTH(RX_QUEUE_INDEX_WIDTH),
    .CQN_WIDTH(CQN_WIDTH),
    .EQ_PIPELINE(EQ_PIPELINE),
    .TX_QUEUE_PIPELINE(TX_QUEUE_PIPELINE),
    .RX_QUEUE_PIPELINE(RX_QUEUE_PIPELINE),
    .CQ_PIPELINE(CQ_PIPELINE),

    // TX and RX engine configuration
    .TX_DESC_TABLE_SIZE(TX_DESC_TABLE_SIZE),
    .RX_DESC_TABLE_SIZE(RX_DESC_TABLE_SIZE),
    .RX_INDIR_TBL_ADDR_WIDTH(RX_INDIR_TBL_ADDR_WIDTH),

    // Scheduler configuration
    .TX_SCHEDULER_OP_TABLE_SIZE(TX_SCHEDULER_OP_TABLE_SIZE),
    .TX_SCHEDULER_PIPELINE(TX_SCHEDULER_PIPELINE),
    .TDMA_INDEX_WIDTH(TDMA_INDEX_WIDTH),

    // Interface configuration
    .PTP_TS_ENABLE(PTP_TS_ENABLE),
    .TX_CPL_FIFO_DEPTH(TX_CPL_FIFO_DEPTH),
    .TX_TAG_WIDTH(TX_TAG_WIDTH),
    .TX_CHECKSUM_ENABLE(TX_CHECKSUM_ENABLE),
    .RX_HASH_ENABLE(RX_HASH_ENABLE),
    .RX_CHECKSUM_ENABLE(RX_CHECKSUM_ENABLE),
    .PFC_ENABLE(PFC_ENABLE),
    .LFC_ENABLE(LFC_ENABLE),
    .ENABLE_PADDING(ENABLE_PADDING),
    .ENABLE_DIC(ENABLE_DIC),
    .MIN_FRAME_LENGTH(MIN_FRAME_LENGTH),
    .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
    .RX_FIFO_DEPTH(RX_FIFO_DEPTH),
    .MAX_TX_SIZE(MAX_TX_SIZE),
    .MAX_RX_SIZE(MAX_RX_SIZE),
    .TX_RAM_SIZE(TX_RAM_SIZE),
    .RX_RAM_SIZE(RX_RAM_SIZE),

    // RAM configuration
    .DDR_CH(DDR_CH),
    .DDR_ENABLE(DDR_ENABLE),
    .AXI_DDR_DATA_WIDTH(AXI_DDR_DATA_WIDTH),
    .AXI_DDR_ADDR_WIDTH(AXI_DDR_ADDR_WIDTH),
    .AXI_DDR_STRB_WIDTH(AXI_DDR_STRB_WIDTH),
    .AXI_DDR_ID_WIDTH(AXI_DDR_ID_WIDTH),
    .AXI_DDR_MAX_BURST_LEN(AXI_DDR_MAX_BURST_LEN),
    .AXI_DDR_NARROW_BURST(AXI_DDR_NARROW_BURST),

    // Application block configuration
    .APP_ID(APP_ID),
    .APP_ENABLE(APP_ENABLE),
    .APP_CTRL_ENABLE(APP_CTRL_ENABLE),
    .APP_DMA_ENABLE(APP_DMA_ENABLE),
    .APP_AXIS_DIRECT_ENABLE(APP_AXIS_DIRECT_ENABLE),
    .APP_AXIS_SYNC_ENABLE(APP_AXIS_SYNC_ENABLE),
    .APP_AXIS_IF_ENABLE(APP_AXIS_IF_ENABLE),
    .APP_STAT_ENABLE(APP_STAT_ENABLE),

    // AXI interface configuration (DMA)
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),

    // DMA interface configuration
    .DMA_IMM_ENABLE(DMA_IMM_ENABLE),
    .DMA_IMM_WIDTH(DMA_IMM_WIDTH),
    .DMA_LEN_WIDTH(DMA_LEN_WIDTH),
    .DMA_TAG_WIDTH(DMA_TAG_WIDTH),
    .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
    .RAM_PIPELINE(RAM_PIPELINE),
    .AXI_DMA_MAX_BURST_LEN(AXI_DMA_MAX_BURST_LEN),

    // Interrupts
    .IRQ_COUNT(IRQ_COUNT),

    // AXI lite interface configuration (control)
    .AXIL_CTRL_DATA_WIDTH(AXIL_CTRL_DATA_WIDTH),
    .AXIL_CTRL_ADDR_WIDTH(AXIL_CTRL_ADDR_WIDTH),
    .AXIL_CTRL_STRB_WIDTH(AXIL_CTRL_STRB_WIDTH),

    // AXI lite interface configuration (application control)
    .AXIL_APP_CTRL_DATA_WIDTH(AXIL_APP_CTRL_DATA_WIDTH),
    .AXIL_APP_CTRL_ADDR_WIDTH(AXIL_APP_CTRL_ADDR_WIDTH),
    .AXIL_APP_CTRL_STRB_WIDTH(AXIL_APP_CTRL_STRB_WIDTH),

    // Ethernet interface configuration
    .XGMII_DATA_WIDTH(XGMII_DATA_WIDTH),
    .XGMII_CTRL_WIDTH(XGMII_CTRL_WIDTH),
    .AXIS_ETH_DATA_WIDTH(AXIS_ETH_DATA_WIDTH),
    .AXIS_ETH_KEEP_WIDTH(AXIS_ETH_KEEP_WIDTH),
    .AXIS_ETH_SYNC_DATA_WIDTH(AXIS_ETH_SYNC_DATA_WIDTH),
    .AXIS_ETH_TX_USER_WIDTH(AXIS_ETH_TX_USER_WIDTH),
    .AXIS_ETH_RX_USER_WIDTH(AXIS_ETH_RX_USER_WIDTH),
    .AXIS_ETH_TX_PIPELINE(AXIS_ETH_TX_PIPELINE),
    .AXIS_ETH_TX_FIFO_PIPELINE(AXIS_ETH_TX_FIFO_PIPELINE),
    .AXIS_ETH_TX_TS_PIPELINE(AXIS_ETH_TX_TS_PIPELINE),
    .AXIS_ETH_RX_PIPELINE(AXIS_ETH_RX_PIPELINE),
    .AXIS_ETH_RX_FIFO_PIPELINE(AXIS_ETH_RX_FIFO_PIPELINE),

    // Statistics counter subsystem
    .STAT_ENABLE(STAT_ENABLE),
    .STAT_DMA_ENABLE(STAT_DMA_ENABLE),
    .STAT_AXI_ENABLE(STAT_AXI_ENABLE),
    .STAT_INC_WIDTH(STAT_INC_WIDTH),
    .STAT_ID_WIDTH(STAT_ID_WIDTH)
)
core_inst (
    /*
     * Clock
     * Synchronous reset
     */
    .clk(zynq_pl_clk),
    .rst(zynq_pl_reset),

    /*
     * PTP clock
     */
    .ptp_clk(clk_125mhz_int),
    .ptp_rst(rst_125mhz_int),
    .ptp_sample_clk(clk_125mhz_int),

    /*
     * Interrupt outputs
     */
    .irq(irq),

    .led(led),

    /*
     * AXI master interface (DMA)
     */
    .m_axi_awid(axi_awid),
    .m_axi_awaddr(axi_awaddr),
    .m_axi_awlen(axi_awlen),
    .m_axi_awsize(axi_awsize),
    .m_axi_awburst(axi_awburst),
    .m_axi_awlock(axi_awlock),
    .m_axi_awcache(axi_awcache),
    .m_axi_awprot(axi_awprot),
    .m_axi_awvalid(axi_awvalid),
    .m_axi_awready(axi_awready),
    .m_axi_wdata(axi_wdata),
    .m_axi_wstrb(axi_wstrb),
    .m_axi_wlast(axi_wlast),
    .m_axi_wvalid(axi_wvalid),
    .m_axi_wready(axi_wready),
    .m_axi_bid(axi_bid),
    .m_axi_bresp(axi_bresp),
    .m_axi_bvalid(axi_bvalid),
    .m_axi_bready(axi_bready),
    .m_axi_arid(axi_arid),
    .m_axi_araddr(axi_araddr),
    .m_axi_arlen(axi_arlen),
    .m_axi_arsize(axi_arsize),
    .m_axi_arburst(axi_arburst),
    .m_axi_arlock(axi_arlock),
    .m_axi_arcache(axi_arcache),
    .m_axi_arprot(axi_arprot),
    .m_axi_arvalid(axi_arvalid),
    .m_axi_arready(axi_arready),
    .m_axi_rid(axi_rid),
    .m_axi_rdata(axi_rdata),
    .m_axi_rresp(axi_rresp),
    .m_axi_rlast(axi_rlast),
    .m_axi_rvalid(axi_rvalid),
    .m_axi_rready(axi_rready),

    /*
     * AXI lite interface configuration (control)
     */
    .s_axil_ctrl_awaddr(axil_ctrl_awaddr),
    .s_axil_ctrl_awprot(axil_ctrl_awprot),
    .s_axil_ctrl_awvalid(axil_ctrl_awvalid),
    .s_axil_ctrl_awready(axil_ctrl_awready),
    .s_axil_ctrl_wdata(axil_ctrl_wdata),
    .s_axil_ctrl_wstrb(axil_ctrl_wstrb),
    .s_axil_ctrl_wvalid(axil_ctrl_wvalid),
    .s_axil_ctrl_wready(axil_ctrl_wready),
    .s_axil_ctrl_bresp(axil_ctrl_bresp),
    .s_axil_ctrl_bvalid(axil_ctrl_bvalid),
    .s_axil_ctrl_bready(axil_ctrl_bready),
    .s_axil_ctrl_araddr(axil_ctrl_araddr),
    .s_axil_ctrl_arprot(axil_ctrl_arprot),
    .s_axil_ctrl_arvalid(axil_ctrl_arvalid),
    .s_axil_ctrl_arready(axil_ctrl_arready),
    .s_axil_ctrl_rdata(axil_ctrl_rdata),
    .s_axil_ctrl_rresp(axil_ctrl_rresp),
    .s_axil_ctrl_rvalid(axil_ctrl_rvalid),
    .s_axil_ctrl_rready(axil_ctrl_rready),

    /*
     * AXI lite interface configuration (application control)
     */
    .s_axil_app_ctrl_awaddr(axil_app_ctrl_awaddr),
    .s_axil_app_ctrl_awprot(axil_app_ctrl_awprot),
    .s_axil_app_ctrl_awvalid(axil_app_ctrl_awvalid),
    .s_axil_app_ctrl_awready(axil_app_ctrl_awready),
    .s_axil_app_ctrl_wdata(axil_app_ctrl_wdata),
    .s_axil_app_ctrl_wstrb(axil_app_ctrl_wstrb),
    .s_axil_app_ctrl_wvalid(axil_app_ctrl_wvalid),
    .s_axil_app_ctrl_wready(axil_app_ctrl_wready),
    .s_axil_app_ctrl_bresp(axil_app_ctrl_bresp),
    .s_axil_app_ctrl_bvalid(axil_app_ctrl_bvalid),
    .s_axil_app_ctrl_bready(axil_app_ctrl_bready),
    .s_axil_app_ctrl_araddr(axil_app_ctrl_araddr),
    .s_axil_app_ctrl_arprot(axil_app_ctrl_arprot),
    .s_axil_app_ctrl_arvalid(axil_app_ctrl_arvalid),
    .s_axil_app_ctrl_arready(axil_app_ctrl_arready),
    .s_axil_app_ctrl_rdata(axil_app_ctrl_rdata),
    .s_axil_app_ctrl_rresp(axil_app_ctrl_rresp),
    .s_axil_app_ctrl_rvalid(axil_app_ctrl_rvalid),
    .s_axil_app_ctrl_rready(axil_app_ctrl_rready),

    /*
     * DDR
     */
    .ddr_clk(ddr_clk),
    .ddr_rst(ddr_rst),

    .m_axi_ddr_awid(m_axi_ddr_awid),
    .m_axi_ddr_awaddr(m_axi_ddr_awaddr),
    .m_axi_ddr_awlen(m_axi_ddr_awlen),
    .m_axi_ddr_awsize(m_axi_ddr_awsize),
    .m_axi_ddr_awburst(m_axi_ddr_awburst),
    .m_axi_ddr_awlock(m_axi_ddr_awlock),
    .m_axi_ddr_awcache(m_axi_ddr_awcache),
    .m_axi_ddr_awprot(m_axi_ddr_awprot),
    .m_axi_ddr_awqos(m_axi_ddr_awqos),
    .m_axi_ddr_awvalid(m_axi_ddr_awvalid),
    .m_axi_ddr_awready(m_axi_ddr_awready),
    .m_axi_ddr_wdata(m_axi_ddr_wdata),
    .m_axi_ddr_wstrb(m_axi_ddr_wstrb),
    .m_axi_ddr_wlast(m_axi_ddr_wlast),
    .m_axi_ddr_wvalid(m_axi_ddr_wvalid),
    .m_axi_ddr_wready(m_axi_ddr_wready),
    .m_axi_ddr_bid(m_axi_ddr_bid),
    .m_axi_ddr_bresp(m_axi_ddr_bresp),
    .m_axi_ddr_bvalid(m_axi_ddr_bvalid),
    .m_axi_ddr_bready(m_axi_ddr_bready),
    .m_axi_ddr_arid(m_axi_ddr_arid),
    .m_axi_ddr_araddr(m_axi_ddr_araddr),
    .m_axi_ddr_arlen(m_axi_ddr_arlen),
    .m_axi_ddr_arsize(m_axi_ddr_arsize),
    .m_axi_ddr_arburst(m_axi_ddr_arburst),
    .m_axi_ddr_arlock(m_axi_ddr_arlock),
    .m_axi_ddr_arcache(m_axi_ddr_arcache),
    .m_axi_ddr_arprot(m_axi_ddr_arprot),
    .m_axi_ddr_arqos(m_axi_ddr_arqos),
    .m_axi_ddr_arvalid(m_axi_ddr_arvalid),
    .m_axi_ddr_arready(m_axi_ddr_arready),
    .m_axi_ddr_rid(m_axi_ddr_rid),
    .m_axi_ddr_rdata(m_axi_ddr_rdata),
    .m_axi_ddr_rresp(m_axi_ddr_rresp),
    .m_axi_ddr_rlast(m_axi_ddr_rlast),
    .m_axi_ddr_rvalid(m_axi_ddr_rvalid),
    .m_axi_ddr_rready(m_axi_ddr_rready),

    .ddr_status(ddr_status)
);

endmodule

`resetall
