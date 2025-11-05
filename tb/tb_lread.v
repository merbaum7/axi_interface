// axi master read testbench wrapper
`timescale 1ns / 1ps

module tb_axi_mr (
	// Control Signals
	input						i_ren,
	input	[31:0]				i_start_address,
	input	[31:0]				i_read_size,
	output						o_rdone,

	input						i_fixed_burst,

	// AXI-Full
	// Global Clock Signal.
	input						M_ACLK,
	// Global Reset Singal. This Signal is Active Low
	input						M_ARESETN,

	// Write
	// - Address
	output	[31:0]				M_AXI_AWADDR,
	output	[2:0]				M_AXI_AWPROT,
	output						M_AXI_AWVALID,
	input						M_AXI_AWREADY,
	// - Data
	output	[31:0]				M_AXI_WDATA,
	output	[3:0]				M_AXI_WSTRB,
	output						M_AXI_WVALID,
	input						M_AXI_WREADY,
	// - Response
	input	[1:0]				M_AXI_BRESP,
	input						M_AXI_BVALID,
	output						M_AXI_BREADY,

	// Read
	// - Address
	output	[31:0]				M_AXI_ARADDR,
	output	[2:0]				M_AXI_ARPROT,
	output						M_AXI_ARVALID,
	input						M_AXI_ARREADY,
	// - Data
	input	[31:0]				M_AXI_RDATA,
	input	[1:0]				M_AXI_RRESP,
	input						M_AXI_RVALID,
	output						M_AXI_RREADY
);

	axi_m_read #(
		.MAX_BURST_LEN		(0),
		.ADDR_WIDTH			(32),
		.DATA_WIDTH			(32)
	) u_axi_m_read (
		.i_ren				(i_ren),
		.i_start_address	(i_start_address),
		.i_read_size		(i_read_size),
		.o_rdone			(o_rdone),

		.i_fixed_burst		(i_fixed_burst),

		.i_fifo_full		(1'b0),
		//.i_fifo_empty		(),
		//.o_fifo_data		(),
		//.o_fifo_en		(),

		.M_ACLK				(M_ACLK),
		.M_ARESETN			(M_ARESETN),

		.M_ARADDR			(M_AXI_ARADDR),
		.M_ARPROT			(M_AXI_ARPROT),
		.M_ARVALID			(M_AXI_ARVALID),
		.M_ARREADY			(M_AXI_ARREADY),

		.M_RDATA			(M_AXI_RDATA),
		.M_RRESP			(M_AXI_RRESP),
		.M_RVALID			(M_AXI_RVALID),
		.M_RREADY			(M_AXI_RREADY)
	);

	`ifdef COCOTB_SIM
	initial begin
		$dumpfile ("axi_m_lread.vcd");
		$dumpvars (0, tb_axi_mr);
		#1;
	end
	`endif
	
endmodule