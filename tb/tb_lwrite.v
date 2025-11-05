// axi master read testbench wrapper
`timescale 1ns / 1ps

module tb_axi_mw (
	// Control Signals
	input						i_wen,
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
		.MAX_BURST_LEN		(0),
		.ADDR_WIDTH			(32),
		.DATA_WIDTH			(32)
	) u_axi_m_write (
		.i_wen				(i_wen),
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

		.M_AWADDR			(M_AXI_AWADDR),
		.M_AWPROT			(M_AXI_AWPROT),
		.M_AWVALID			(M_AXI_AWVALID),
		.M_AWREADY			(M_AXI_AWREADY),

		.M_WDATA			(M_AXI_WDATA),
		.M_WSTRB			(M_AXI_WSTRB),
		.M_WVALID			(M_AXI_WVALID),
		.M_WREADY			(M_AXI_WREADY),
		
		.M_BRESP			(M_AXI_BRESP),
		.M_BVALID			(M_AXI_BVALID),
		.M_BREADY			(M_AXI_BREADY)
	);

	`ifdef COCOTB_SIM
	initial begin
		$dumpfile ("axi_m_lwrite.vcd");
		$dumpvars (0, tb_axi_mw);
		#1;
	end
	`endif
	
endmodule