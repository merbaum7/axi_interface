// axi master read testbench wrapper
`timescale 1ns / 1ps

module tb_axi_mw (
	// Control Signals
	input						i_wstart,
	input	[31:0]				i_start_address,
	input	[31:0]				i_write_size,
	output						o_wdone,

	input						i_fixed_burst,

	// AXI-Full
	// Global Clock Signal.
	input						M_ACLK,
	// Global Reset Singal. This Signal is Active Low
	input						M_ARESETN,

	// Write
	// - Address
	output						M_AXI_AWID,
	output	[31:0]				M_AXI_AWADDR,
	output	[7:0]				M_AXI_AWLEN,
	output	[2:0]				M_AXI_AWSIZE,
	output	[1:0]				M_AXI_AWBURST,
	output						M_AXI_AWLOCK,
	output	[3:0]				M_AXI_AWCACHE,
	output	[2:0]				M_AXI_AWQOS,
	output						M_AXI_AWUSER,
	output	[2:0]				M_AXI_AWPROT,
	output						M_AXI_AWVALID,
	input						M_AXI_AWREADY,
	// - Data
	output	[31:0]				M_AXI_WDATA,
	output	[3:0]				M_AXI_WSTRB,
	output						M_AXI_WLAST,
	output						M_AXI_WUSER,
	output						M_AXI_WVALID,
	input						M_AXI_WREADY,
	// - Response
	input						M_AXI_BID,
	input	[1:0]				M_AXI_BRESP,
	input						M_AXI_BUSER,
	input						M_AXI_BVALID,
	output						M_AXI_BREADY,

	// Read
	// - Address
	output						M_AXI_ARID,
	output	[31:0]				M_AXI_ARADDR,
	output	[7:0]				M_AXI_ARLEN,
	output	[2:0]				M_AXI_ARSIZE,
	output	[1:0]				M_AXI_ARBURST,
	output						M_AXI_ARLOCK,
	output	[3:0]				M_AXI_ARCACHE,
	output	[2:0]				M_AXI_ARPROT,
	output	[3:0]				M_AXI_ARQOS,
	output						M_AXI_ARUSER,
	output						M_AXI_ARVALID,
	input						M_AXI_ARREADY,
	// - Data
	input						M_AXI_RID,
	input	[31:0]				M_AXI_RDATA,
	input	[1:0]				M_AXI_RRESP,
	input						M_AXI_RLAST,
	input						M_AXI_RUSER,
	input						M_AXI_RVALID,
	output						M_AXI_RREADY
);

	reg		[31:0]				r_data;
	wire						w_fifo_en;

	always @(posedge M_ACLK) begin
		if (!M_ARESETN) begin
			r_data	<=	32'h0000_0000;
		end
		else begin
			if (w_fifo_en) begin
				r_data	<=	r_data + 1;
			end
		end
	end

	axi_m_write #(
		.MAX_BURST_LEN		(256),
		.ADDR_WIDTH			(32),
		.DATA_WIDTH			(32)
	) u_axi_m_write (
		.i_wstart			(i_wstart),
		.i_start_address	(i_start_address),
		.i_write_size		(i_write_size),
		.o_wdone			(o_wdone),

		.i_fixed_burst		(i_fixed_burst),

		//.i_fifo_full		(1'b0),
		.i_fifo_empty		(1'b0),
		.i_fifo_data		(r_data),
		.o_fifo_en			(w_fifo_en),

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

	`ifdef COCOTB_SIM
	initial begin
		$dumpfile ("axi_m_write.vcd");
		$dumpvars (0, tb_axi_mw);
		#1;
	end
	`endif
	
endmodule