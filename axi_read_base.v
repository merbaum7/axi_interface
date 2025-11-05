module axi_m_read #(
	parameter integer	MAX_BURST_LEN	=	256,
	parameter integer	ADDR_WIDTH		=	32,
	parameter integer	DATA_WIDTH		=	32,

	parameter integer	ID_WIDTH		=	1,
	parameter integer	AUSER_WIDTH		=	1,
	parameter integer	USER_WIDTH		=	1
) (
	// Control Signals
	input						i_ren,
	input	[ADDR_WIDTH-1:0]	i_start_address,
	input	[31:0]				i_read_size,
	output						o_rdone,

	input						i_fixed_burst,

	// FIFO Interface
	input						i_fifo_full,
	output	[DATA_WIDTH-1:0]	o_fifo_data,
	output						o_fifo_en,

	// AXI-Full
	// Global Clock Signal.
	input						M_ACLK,
	// Global Reset Singal. This Signal is Active Low
	input						M_ARESETN,

	// - Address
	output	[ID_WIDTH-1:0]		M_ARID,
	output	[ADDR_WIDTH-1:0]	M_ARADDR,
	output	[7:0]				M_ARLEN,
	output	[2:0]				M_ARSIZE,
	output	[1:0]				M_ARBURST,
	output						M_ARLOCK,
	output	[3:0]				M_ARCACHE,
	output	[2:0]				M_ARPROT,
	output	[3:0]				M_ARQOS,
	output	[AUSER_WIDTH-1:0]	M_ARUSER,
	output						M_ARVALID,
	input						M_ARREADY,
	// - Data
	input	[ID_WIDTH-1:0]		M_RID,
	input	[DATA_WIDTH-1:0]	M_RDATA,
	input	[1:0]				M_RRESP,
	input						M_RLAST,
	input	[USER_WIDTH-1:0]	M_RUSER,
	input						M_RVALID,
	output						M_RREADY
);
	function integer clogb2 (input integer bit_depth); 
	begin 
		for(clogb2=0; bit_depth>0; clogb2=clogb2+1) 
			bit_depth = bit_depth >> 1; 
	end 
	endfunction 

	// Read State list
	parameter	[2:0]	IDLE			=	3'b000, 
						INIT_READ		=	3'b001,
						READ_DATA		=	3'b010,
						READ_DATA_END	=	3'b011,
						READ_END		=	3'b100,
						GAP				=	3'b101;

	localparam integer	TNUM			=	clogb2(MAX_BURST_LEN-1);

	reg		[2:0]				r_rstate;		// read state register
	reg		[31:0]				r_total_size;	// total read data size
	reg		[31:0]				r_rem_size;		// data counter

	reg							r_reads_done;

	reg		[7:0]				r_burst_count;	// data counter
	reg							r_burst_addr;
	reg							r_burst_busy;

	reg							r_arvalid;
	reg							r_rready;

	reg 	[ADDR_WIDTH-1 : 0] 	r_araddr;

	wire						rnext = M_RVALID && r_rready;

	//Read Address (AR)
	assign M_ARID			=	'b0;
	assign M_ARADDR			=	r_araddr;
	//Burst length
	assign M_ARLEN			=	(r_rem_size > MAX_BURST_LEN*(DATA_WIDTH/8)) ? MAX_BURST_LEN-1 : ((r_rem_size/(DATA_WIDTH/8))-1);
	//Size should be C_M_AXI_DATA_WIDTH, in 2^n bytes, otherwise narrow bursts are used
	assign M_ARSIZE			=	clogb2((DATA_WIDTH/8)-1);
	//INCR burst type 00:Fixed, 01:Increment
	assign M_ARBURST		=	(i_fixed_burst) ? 2'b00 : 2'b01;

	//Read address request valid Response
	assign M_ARVALID		=	r_arvalid;
	//Read and Read Response
	assign M_RREADY			=	r_rready;

	assign M_RRESP			=	2'b00;	// OKAY

	// Unused
	assign M_RUSER		= 'b0;
	assign M_ARUSER		= 'b0;
	assign M_ARLOCK		= 1'b0;
	assign M_ARCACHE	= 4'b0010;
	assign M_ARPROT		= 3'h0;
	assign M_ARQOS		= 4'h0;

	// Main State Machine
	always @(posedge M_ACLK) begin
		if ( M_ARESETN == 0 ) begin
			r_rstate		<=	IDLE;
			r_burst_addr	<=	1'b0;
			r_total_size	<=	32'b0;
			r_rem_size		<=	32'b0;
		end else begin
			case (r_rstate)
				IDLE: begin				// 待機状態: 読み出し要求待ち
					if (i_ren) begin
						r_total_size	<=	i_read_size;
						r_rem_size		<=	i_read_size;
						r_rstate		<=	INIT_READ;
						r_burst_addr	<=	1'b0;
					end else begin
						r_rstate	<=	IDLE;
					end
				end
				INIT_READ: begin		// 読み出しアドレス発行
					r_rstate	<=	READ_DATA;
				end
				READ_DATA: begin
					if (r_reads_done) begin
						r_rstate	<=	READ_DATA_END;
					end else begin
						r_rstate	<=	READ_DATA;
						if (~r_arvalid && ~r_burst_addr && ~r_burst_busy) begin
							r_burst_addr	<=	1'b1;
						end else if (r_arvalid && M_ARREADY) begin
							r_burst_addr	<=	1'b0;
						end
					end
				end
				READ_DATA_END: begin	// 読み出しデータ量の判定
					if (MAX_BURST_LEN == 0) begin
						if (r_rem_size <= DATA_WIDTH/8) begin	
							r_rstate	<=	READ_END;
							r_rem_size	<=	0;
						end else begin
							r_rstate	<=	INIT_READ;
							r_rem_size	<=	r_rem_size - DATA_WIDTH/8;
						end
					end else begin
						if (r_rem_size <= MAX_BURST_LEN*(DATA_WIDTH/8)) begin	
							r_rstate	<=	READ_END;
							r_rem_size	<=	0;
						end else begin
							r_rstate	<=	INIT_READ;
							r_rem_size	<=	r_rem_size - MAX_BURST_LEN*(DATA_WIDTH/8);
						end
					end 
				end
				READ_END: begin
					if(~i_ren)
						r_rstate	<=	GAP;
				end
				GAP: begin
					r_rstate	<=	IDLE;
				end
				default: begin
					r_rstate	<=	IDLE;
				end
			endcase
		end
	end

	assign	o_rdone = (r_rstate == READ_END);

	// Read Address Channel
	always @(posedge M_ACLK) begin 
		if ( M_ARESETN == 0 ) begin
			r_arvalid <= 1'b0;
		end else if ( ~r_arvalid && r_burst_addr && ~r_rready ) begin
			r_arvalid <= 1'b1;
		end else if ( M_ARREADY && r_arvalid ) begin
			r_arvalid <= 1'b0;
		end else begin
			r_arvalid <= r_arvalid;
		end
	end
	

	// Read Address Generation 
	generate//: Read_address_gen
		if (MAX_BURST_LEN == 0) begin
			always @(posedge M_ACLK) begin
				if ( M_ARESETN == 0 ) begin
					r_araddr	<=	32'b0;
				end else if (r_rstate == IDLE) begin
					if (i_ren)
						r_araddr	<=	i_start_address;
				end else if (M_ARREADY && r_arvalid) begin
					if (i_fixed_burst)
						r_araddr	<=	r_araddr;
					else 
						r_araddr	<=	r_araddr + DATA_WIDTH/8;
				end else begin
					r_araddr 	<=	r_araddr;
				end
			end
		end else begin
			always @(posedge M_ACLK) begin
				if ( M_ARESETN == 0 ) begin
					r_araddr	<=	32'b0;
				end else if (r_rstate == IDLE) begin
					if (i_ren)
						r_araddr	<=	i_start_address;
				end else if (M_ARREADY && r_arvalid) begin
					if (M_ARBURST == 2'b00)
						r_araddr	<=	r_araddr;
					else if (M_ARBURST == 2'b01)
						r_araddr	<=	r_araddr + MAX_BURST_LEN*(DATA_WIDTH/8);
				end else begin
					r_araddr <= r_araddr;
				end
			end
		end
	endgenerate 
	
	// Burst Size Calc
	generate//: Read_burst_size_calc
		if (MAX_BURST_LEN != 0) begin
			always @(posedge M_ACLK) begin
				if ( M_ARESETN == 1'b0 || r_rstate == READ_END) begin
					r_burst_count	<=	0;
				end else begin
					if (rnext) begin
						r_burst_count	<=	r_burst_count + 1;
					end else begin
						r_burst_count	<=	r_burst_count;
					end
				end
			end
		end
	endgenerate

	// Read Transaction
	generate//: Read_ready
		if (MAX_BURST_LEN == 0) begin
			always @(posedge M_ACLK) begin	// burst busy flag
				if (M_ARESETN == 0) begin
					r_burst_busy <= 1'b0;                                                                            
				end else if (r_burst_addr) begin
					r_burst_busy <= 1'b1;
				end else if (rnext) begin
					r_burst_busy <= 0;
				end
			end

			always @(posedge M_ACLK) begin
				if (M_ARESETN == 0 ) begin
					r_rready <= 1'b0;
				end else if (M_RVALID || M_ARREADY && M_ARVALID) begin
					if (r_rready) begin
						r_rready <= 1'b0;
					end else begin
						r_rready <= !i_fifo_full;
					end
				end
			end
		end else begin
			always @(posedge M_ACLK) begin	// burst busy flag
				if (M_ARESETN == 0) begin
					r_burst_busy <= 1'b0;                                                                            
				end else if (r_burst_addr) begin
					r_burst_busy <= 1'b1;
				end else if (rnext && M_RLAST) begin
					r_burst_busy <= 0;
				end
			end

			always @(posedge M_ACLK) begin		// read ready signal
				if (M_ARESETN == 0 ) begin
					r_rready <= 1'b0;
				end else if (M_RVALID) begin
					if (r_rready && M_RLAST) begin
						r_rready <= 1'b0;
					end else begin
						r_rready <= !i_fifo_full;
					end
				end
			end
		end
	endgenerate

	// Read Done Flag
	generate
		if (MAX_BURST_LEN == 0) begin
			always @(posedge M_ACLK) begin	// burst read done flag
				if (M_ARESETN == 0) begin
					r_reads_done	<=	1'b0;
				end else if (r_rstate == READ_DATA_END ||
								r_rstate == READ_END) begin
					r_reads_done	<=	1'b0;
				end else if (rnext) begin
					r_reads_done	<=	1'b1;
				end else begin
					r_reads_done	<=	r_reads_done;
				end
			end
		end else begin
			always @(posedge M_ACLK) begin	// burst read done flag
				if (M_ARESETN == 0) begin
					r_reads_done	<=	1'b0;
				end else if (r_rstate == READ_DATA_END ||
								r_rstate == READ_END) begin
					r_reads_done	<=	1'b0;
				end else if (rnext && M_RLAST) begin
					r_reads_done	<=	1'b1;
				end else begin
					r_reads_done	<=	r_reads_done;
				end
			end
		end
	endgenerate

	// Read Data Write to FIFO
	assign	o_fifo_data = M_RDATA;
	assign	o_fifo_en = rnext;
	
endmodule