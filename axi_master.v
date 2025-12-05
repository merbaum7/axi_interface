module axi_master #(
	parameter 			AXI_FULL		=	"-",
	parameter 			AXI_RW			=	"R/W",

	parameter integer	MAX_BURST_LEN	=	256,
	parameter integer	ADDR_WIDTH		=	32,
	parameter integer	DATA_WIDTH		=	32,

	parameter integer	ID_WIDTH		=	1,
	parameter integer	USER_WIDTH		=	1
) (
	// Control Signals (write)
	input						i_wstart,
	input	[ADDR_WIDTH-1:0]	i_wstart_address,
	input	[31:0]				i_write_size,
	output						o_wdone,

    input						i_wfixed_burst,

	// FIFO Interface (write)
	input						i_wfifo_empty,
	input	[DATA_WIDTH-1:0]	i_wfifo_data,
	output						o_wfifo_wen,


    // Control Signals (read)
	input						i_rstart,
	input	[ADDR_WIDTH-1:0]	i_rstart_address,
	input	[31:0]				i_read_size,
	output						o_rdone,

	input						i_rfixed_burst,

	// FIFO Interface (read)
	input						i_rfifo_full,
	output	[DATA_WIDTH-1:0]	o_rfifo_data,
	output						o_rfifo_ren,

	// AXI-Full
	// Global Clock Signal.
	input						M_ACLK,
	// Global Reset Singal. This Signal is Active Low
	input						M_ARESETN,

	// Write
	// - Address
	output	[ID_WIDTH-1:0]		M_AXI_AWID,
	output	[ADDR_WIDTH-1:0]	M_AXI_AWADDR,
	output	[7:0]				M_AXI_AWLEN,
	output	[2:0]				M_AXI_AWSIZE,
	output	[1:0]				M_AXI_AWBURST,
	output						M_AXI_AWLOCK,
	output	[3:0]				M_AXI_AWCACHE,
	output	[2:0]				M_AXI_AWQOS,
	output	[USER_WIDTH-1:0]	M_AXI_AWUSER,
	output	[2:0]				M_AXI_AWPROT,
	output						M_AXI_AWVALID,
	input						M_AXI_AWREADY,
	// - Data
	output	[DATA_WIDTH-1:0]	M_AXI_WDATA,
	output	[DATA_WIDTH/8-1:0]	M_AXI_WSTRB,
	output						M_AXI_WLAST,
	output	[USER_WIDTH-1:0]	M_AXI_WUSER,
	output						M_AXI_WVALID,
	input						M_AXI_WREADY,
	// - Response
	input	[ID_WIDTH-1:0]		M_AXI_BID,
	input	[1:0]				M_AXI_BRESP,
	input	[USER_WIDTH-1:0]	M_AXI_BUSER,
	input						M_AXI_BVALID,
	output						M_AXI_BREADY,

	// Read
	// - Address
	output	[ID_WIDTH-1:0]		M_AXI_ARID,
	output	[ADDR_WIDTH-1:0]	M_AXI_ARADDR,
	output	[7:0]				M_AXI_ARLEN,
	output	[2:0]				M_AXI_ARSIZE,
	output	[1:0]				M_AXI_ARBURST,
	output						M_AXI_ARLOCK,
	output	[3:0]				M_AXI_ARCACHE,
	output	[2:0]				M_AXI_ARPROT,
	output	[3:0]				M_AXI_ARQOS,
	output	[USER_WIDTH-1:0]	M_AXI_ARUSER,
	output						M_AXI_ARVALID,
	input						M_AXI_ARREADY,
	// - Data
	input	[ID_WIDTH-1:0]		M_AXI_RID,
	input	[DATA_WIDTH-1:0]	M_AXI_RDATA,
	input	[1:0]				M_AXI_RRESP,
	input						M_AXI_RLAST,
	input	[USER_WIDTH-1:0]	M_AXI_RUSER,
	input						M_AXI_RVALID,
	output						M_AXI_RREADY
);

	generate
		if (AXI_FULL == "ON" && MAX_BURST_LEN != 0 || AXI_FULL == "OFF" && MAX_BURST_LEN == 0) begin : gen_axi
			if (AXI_RW == "R/W" || AXI_RW == "W") begin : gen_axi_write
				axi_m_write #(
					.MAX_BURST_LEN		(MAX_BURST_LEN),

					.ADDR_WIDTH			(ADDR_WIDTH),
					.DATA_WIDTH			(DATA_WIDTH),
					.ID_WIDTH			(ID_WIDTH),
					.USER_WIDTH			(USER_WIDTH)
				) u_axi_write_base (
					.i_wstart			(i_wstart),
					.i_start_address	(i_wstart_address),
					.i_write_size		(i_write_size),
					.o_wdone			(o_wdone),

					.i_fixed_burst		(i_wfixed_burst),

					.i_fifo_empty		(i_wfifo_empty),
					.i_fifo_data		(i_wfifo_data),
					.o_fifo_en			(o_wfifo_wen),

					.M_ACLK				(M_ACLK),
					.M_ARESETN			(M_ARESETN),

					.M_AWID				(M_AXI_AWID),
					.M_AWADDR			(M_AXI_AWADDR),
					.M_AWLEN			(M_AXI_AWLEN),
					.M_AWSIZE			(M_AXI_AWSIZE),
					.M_AWBURST			(M_AXI_AWBURST),
					.M_AWLOCK			(M_AXI_AWLOCK),
					.M_AWCACHE			(M_AXI_AWCACHE),
					.M_AWQOS			(M_AXI_AWQOS),
					.M_AWUSER			(M_AXI_AWUSER),
					.M_AWPROT			(M_AXI_AWPROT),
					.M_AWVALID			(M_AXI_AWVALID),
					.M_AWREADY			(M_AXI_AWREADY),

					.M_WDATA			(M_AXI_WDATA),
					.M_WSTRB			(M_AXI_WSTRB),
					.M_WLAST			(M_AXI_WLAST),
					.M_WUSER			(M_AXI_WUSER),
					.M_WVALID			(M_AXI_WVALID),
					.M_WREADY			(M_AXI_WREADY),

					.M_BID				(M_AXI_BID),
					.M_BRESP			(M_AXI_BRESP),
					.M_BUSER			(M_AXI_BUSER),
					.M_BVALID			(M_AXI_BVALID),
					.M_BREADY			(M_AXI_BREADY)
				);
			end else begin
				assign	o_wdone			=	1'bx;
				assign	o_wfifo_wen		=	1'bx;
				assign	M_AXI_AWID		=	{ID_WIDTH{1'bx}};
				assign	M_AXI_AWADDR	=	{ADDR_WIDTH{1'bx}};
				assign	M_AXI_AWLEN		=	8'hxx;
				assign	M_AXI_AWSIZE	=	3'bxxx;
				assign	M_AXI_AWBURST	=	2'bxx;
				assign	M_AXI_AWLOCK	=	1'bx;
				assign	M_AXI_AWCACHE	=	4'bxxxx;
				assign	M_AXI_AWQOS		=	3'bxxx;
				assign	M_AXI_AWUSER	=	{USER_WIDTH{1'bx}};
				assign	M_AXI_AWPROT	=	3'bxxx;
				assign	M_AXI_AWVALID	=	1'bx;
				assign	M_AXI_WDATA		=	{DATA_WIDTH{1'bx}};
				assign	M_AXI_WSTRB		=	{(DATA_WIDTH/8){1'bx}};
				assign	M_AXI_WLAST		=	1'bx;
				assign	M_AXI_WUSER		=	{USER_WIDTH{1'bx}};
				assign	M_AXI_WVALID	=	1'bx;
				assign	M_AXI_BREADY	=	1'bx;
			end

			if (AXI_RW == "R/W" || AXI_RW == "R") begin : gen_axi_read
				axi_m_read #(
					.MAX_BURST_LEN		(MAX_BURST_LEN),

					.ADDR_WIDTH			(ADDR_WIDTH),
					.DATA_WIDTH			(DATA_WIDTH),
					.ID_WIDTH			(ID_WIDTH),
					.USER_WIDTH			(USER_WIDTH)
				) u_axi_read_base (
					.i_rstart			(i_rstart),
					.i_start_address	(i_rstart_address),
					.i_read_size		(i_read_size),
					.o_rdone			(o_rdone),

					.i_fixed_burst		(i_rfixed_burst),

					.i_fifo_full		(i_rfifo_full),
					.o_fifo_data		(o_rfifo_data),
					.o_fifo_en			(o_rfifo_ren),

					.M_ACLK				(M_ACLK),
					.M_ARESETN			(M_ARESETN),

					.M_ARID				(M_AXI_ARID),
					.M_ARADDR			(M_AXI_ARADDR),
					.M_ARLEN			(M_AXI_ARLEN),
					.M_ARSIZE			(M_AXI_ARSIZE),
					.M_ARBURST			(M_AXI_ARBURST),
					.M_ARLOCK			(M_AXI_ARLOCK),
					.M_ARCACHE			(M_AXI_ARCACHE),
					.M_ARPROT			(M_AXI_ARPROT),
					.M_ARQOS			(M_AXI_ARQOS),
					.M_ARUSER			(M_AXI_ARUSER),
					.M_ARVALID			(M_AXI_ARVALID),
					.M_ARREADY			(M_AXI_ARREADY),

					.M_RID				(M_AXI_RID),
					.M_RDATA			(M_AXI_RDATA),
					.M_RRESP			(M_AXI_RRESP),
					.M_RLAST			(M_AXI_RLAST),
					.M_RUSER			(M_AXI_RUSER),
					.M_RVALID			(M_AXI_RVALID),
					.M_RREADY			(M_AXI_RREADY)
				);
			end else begin
				assign	o_rdone			=	1'bx;
				assign	o_rfifo_data	=	{DATA_WIDTH{1'bx}};
				assign	o_rfifo_ren		=	1'bx;
				assign	M_AXI_ARID		=	{ID_WIDTH{1'bx}};
				assign	M_AXI_ARADDR	=	{ADDR_WIDTH{1'bx}};
				assign	M_AXI_ARLEN		=	8'hxx;
				assign	M_AXI_ARSIZE	=	3'bxxx;
				assign	M_AXI_ARBURST	=	2'bxx;
				assign	M_AXI_ARLOCK	=	1'bx;
				assign	M_AXI_ARCACHE	=	4'bxxxx;
				assign	M_AXI_ARPROT	=	3'bxxx;
				assign	M_AXI_ARQOS		=	3'bxxx;
				assign	M_AXI_ARUSER	=	{USER_WIDTH{1'bx}};
				assign	M_AXI_ARVALID	=	1'bx;
				assign	M_AXI_RREADY	=	1'bx;
			end
		end else begin
			error uninplement_module();
		end
	endgenerate
	
endmodule