module axi_m_write #(
	parameter integer	MAX_BURST_LEN	=	256,
	parameter integer	ADDR_WIDTH		=	32,
	parameter integer	DATA_WIDTH		=	32,

	parameter integer	ID_WIDTH		=	1,
	parameter integer	USER_WIDTH		=	1
) (
	// Control Signals
	input						i_wstart,
	input	[ADDR_WIDTH-1:0]	i_start_address,
	input	[31:0]				i_write_size,
	output						o_wdone,

	output	[31:0]				o_rem_write_size,
	input						i_fixed_burst,

	// FIFO Interface
	input						i_fifo_empty,
	input	[DATA_WIDTH-1:0]	i_fifo_data,
	output						o_fifo_en,

	// AXI-Full
	// Global Clock Signal.
	input						M_ACLK,
	// Global Reset Singal. This Signal is Active Low
	input						M_ARESETN,
	
	// - Address
	output	[ID_WIDTH-1:0]		M_AWID,
	output	[ADDR_WIDTH-1:0]	M_AWADDR,
	output	[7:0]				M_AWLEN,
	output	[2:0]				M_AWSIZE,
	output	[1:0]				M_AWBURST,
	output						M_AWLOCK,
	output	[3:0]				M_AWCACHE,
	output	[2:0]				M_AWQOS,
	output	[USER_WIDTH-1:0]	M_AWUSER,
	output	[2:0]				M_AWPROT,
	output						M_AWVALID,
	input						M_AWREADY,
	// - Data
	output	[DATA_WIDTH-1:0]	M_WDATA,
	output	[DATA_WIDTH/8-1:0]	M_WSTRB,
	output						M_WLAST,
	output	[USER_WIDTH-1:0]	M_WUSER,
	output						M_WVALID,
	input						M_WREADY,
	// - Response
	input	[ID_WIDTH-1:0]		M_BID,
	input	[1:0]				M_BRESP,
	input	[USER_WIDTH-1:0]	M_BUSER,
	input						M_BVALID,
	output						M_BREADY
);
	function integer clogb2 (input integer bit_depth); 
	begin 
		for(clogb2=0; bit_depth>0; clogb2=clogb2+1) 
			bit_depth = bit_depth >> 1; 
	end 
	endfunction 

	// Read State list
	parameter	[2:0]	IDLE			=	3'b000, 
						INIT_WRITE		=	3'b001,
						WRITE_DATA		=	3'b010,
						WRITE_DATA_END	=	3'b011,
						WRITE_END		=	3'b100,
						GAP				=	3'b101;

	localparam integer	TNUM			=	clogb2(MAX_BURST_LEN-1);

	reg		[2:0]				r_wstate;		// warite state register
	reg		[31:0]				r_total_size;	// total write data size
	reg		[31:0]				r_rem_size;		// data counter

	reg							r_writes_done;

	reg		[7:0]				r_burst_count;	// data counter
	reg							r_burst_addr;
	reg							r_burst_busy;
	reg							r_burst_resp;

	reg							r_awvalid;
	wire						w_wvalid;
	reg							r_bready;

	reg 	[ADDR_WIDTH-1 : 0] 	r_awaddr;

	wire						wnext = M_WREADY && w_wvalid;
	assign						o_rem_write_size = r_rem_size;

	//Read Address (AR)
	assign M_AWID			=	'b0;
	assign M_AWADDR			=	r_awaddr;
	//Burst length
	assign M_AWLEN			=	(r_rem_size > MAX_BURST_LEN*(DATA_WIDTH/8)) ? MAX_BURST_LEN-1 : 
								(r_rem_size == 0) ? 8'd0 : 
								((r_rem_size/(DATA_WIDTH/8))-1);
	//Size should be C_M_AXI_DATA_WIDTH, in 2^n bytes, otherwise narrow bursts are used
	assign M_AWSIZE			=	clogb2((DATA_WIDTH/8)-1);
	//INCR burst type 00:Fixed, 01:Increment
	assign M_AWBURST		=	(i_fixed_burst) ? 2'b00 : 2'b01;

	//Write address request valid Response
	assign M_AWVALID		=	r_awvalid;
	//Write and Read Response
	assign M_WVALID			=	w_wvalid;
	assign M_WSTRB			=	{(DATA_WIDTH/8){1'b1}};
	
	assign M_WDATA			=	i_fifo_data;
	assign o_fifo_en		=	wnext;

	assign M_BREADY			=	r_bready;

	// Unused
	assign M_WUSER		= 'b0;
	assign M_AWUSER		= 'b0;
	assign M_AWLOCK		= 1'b0;
	assign M_AWCACHE	= 4'b0010;
	assign M_AWPROT		= 3'h0;
	assign M_AWQOS		= 4'h0;

	// Main State Machine
	always @(posedge M_ACLK) begin
		if ( M_ARESETN == 0 ) begin
			r_wstate		<=	IDLE;
			r_burst_addr	<=	1'b0;
			r_total_size	<=	32'b0;
			r_rem_size		<=	32'b0;
		end else begin
			case (r_wstate)
				IDLE: begin				// 待機状態: 書き込み要求待ち
					if (i_wstart) begin
						r_total_size	<=	i_write_size;
						r_rem_size		<=	i_write_size;
						r_wstate		<=	INIT_WRITE;
						r_burst_addr	<=	1'b0;
					end else begin
						r_wstate	<=	IDLE;
					end
				end
				INIT_WRITE: begin		// 書き込みアドレス発行
					r_wstate	<=	WRITE_DATA;
				end
				WRITE_DATA: begin
					if (r_writes_done) begin
						r_wstate	<=	WRITE_DATA_END;
					end else begin
						r_wstate	<=	WRITE_DATA;
						if (~r_awvalid && ~r_burst_addr && ~r_burst_busy) begin
							r_burst_addr	<=	1'b1;
						end else if (r_awvalid && M_AWREADY) begin
							r_burst_addr	<=	1'b0;
						end
					end
				end
				WRITE_DATA_END: begin	// 書き込みデータ量の判定
					if (MAX_BURST_LEN == 0) begin
						if (r_rem_size <= DATA_WIDTH/8) begin	
							r_wstate	<=	WRITE_END;
							r_rem_size	<=	0;
						end else begin
							r_wstate	<=	INIT_WRITE;
							r_rem_size	<=	r_rem_size - DATA_WIDTH/8;
						end
					end else begin
						if (M_BVALID && r_bready) begin
							if (r_rem_size <= MAX_BURST_LEN*(DATA_WIDTH/8)) begin	
								r_wstate	<=	WRITE_END;
								r_rem_size	<=	0;
							end else begin
								r_wstate	<=	INIT_WRITE;
								r_rem_size	<=	r_rem_size - MAX_BURST_LEN*(DATA_WIDTH/8);
							end
						end
					end 
				end
				WRITE_END: begin
					if(~i_wstart)
						r_wstate	<=	GAP;
				end
				GAP: begin
					r_wstate	<=	IDLE;
				end
				default: begin
					r_wstate	<=	IDLE;
				end
			endcase
		end
	end

	assign	o_wdone = (r_wstate == WRITE_END);

	// Write Address Channel
	generate
		if (MAX_BURST_LEN == 0) begin
			always @(posedge M_ACLK) begin 
				if ( M_ARESETN == 0 ) begin
					r_awvalid <= 1'b0;
				end else if ( ~r_awvalid && r_burst_addr ) begin
					r_awvalid <= !i_fifo_empty;
				end else if ( M_AWREADY && r_awvalid ) begin
					r_awvalid <= 1'b0;
				end else begin
					r_awvalid <= r_awvalid;
				end
			end
		end else begin
			always @(posedge M_ACLK) begin 
				if ( M_ARESETN == 0 ) begin
					r_awvalid <= 1'b0;
				end else if ( ~r_awvalid && r_burst_addr && ~w_wvalid ) begin
					r_awvalid <= 1'b1;
				end else if ( M_AWREADY && r_awvalid ) begin
					r_awvalid <= 1'b0;
				end else begin
					r_awvalid <= r_awvalid;
				end
			end
		end
	endgenerate

	// Write Address Generation 
	generate//: Write_address_gen
		if (MAX_BURST_LEN == 0) begin
			always @(posedge M_ACLK) begin
				if ( M_ARESETN == 0 ) begin
					r_awaddr	<=	32'b0;
				end else if (r_wstate == IDLE) begin
					if (i_wstart)
						r_awaddr	<=	i_start_address;
				end else if (M_AWREADY && r_awvalid) begin
					if (i_fixed_burst)
						r_awaddr	<=	r_awaddr;
					else 
						r_awaddr	<=	r_awaddr + DATA_WIDTH/8;
				end else begin
					r_awaddr 	<=	r_awaddr;
				end
			end
		end else begin
			always @(posedge M_ACLK) begin
				if ( M_ARESETN == 0 ) begin
					r_awaddr	<=	32'b0;
				end else if (r_wstate == IDLE) begin
					if (i_wstart)
						r_awaddr	<=	i_start_address;
				end else if (M_AWREADY && r_awvalid) begin
					if (M_AWBURST == 2'b00)
						r_awaddr	<=	r_awaddr;
					else if (M_AWBURST == 2'b01)
						r_awaddr	<=	r_awaddr + MAX_BURST_LEN*(DATA_WIDTH/8);
				end else begin
					r_awaddr <= r_awaddr;
				end
			end
		end
	endgenerate 

	// Burst Size Calc
	generate//: Write_burst_size_calc
		if (MAX_BURST_LEN != 0) begin
			always @(posedge M_ACLK) begin
				if ( M_ARESETN == 1'b0 || r_wstate == WRITE_END) begin
					r_burst_count	<=	0;
				end else begin
					if (wnext) begin
						r_burst_count	<=	r_burst_count + 1;
					end else begin
						r_burst_count	<=	r_burst_count;
					end
				end
			end
		end
	endgenerate

	// こめんと - LiteならAW,W,Bすべて同時でもよく、FullならAWのready,validの＆でWチャネルを起動すればいい
	// Write Transaction
	generate//: Write_ready
		if (MAX_BURST_LEN == 0) begin
			always @(posedge M_ACLK) begin	// burst busy flag
				if (M_ARESETN == 0) begin
					r_burst_busy <= 1'b0;                                                                            
				end else if (r_burst_addr) begin
					r_burst_busy <= 1'b1;
				end else if (M_BREADY && M_BVALID) begin
					r_burst_busy <= 0;
				end
			end

			assign	w_wvalid	=	(r_burst_busy && M_WREADY) ? !i_fifo_empty : 1'b0;
			assign	M_WLAST		=	0;
			// always @(posedge M_ACLK) begin 
			// 	if ( M_ARESETN == 0 ) begin
			// 		r_wvalid <= 1'b0;
			// 	end else if ( ~r_wvalid && r_burst_addr ) begin
			// 		r_wvalid <= !i_fifo_empty;
			// 	end else if ( M_WREADY && r_wvalid ) begin
			// 		r_wvalid <= 1'b0;
			// 	end else begin
			// 		r_wvalid <= r_wvalid;
			// 	end
			// end
		end else begin
			always @(posedge M_ACLK) begin	// burst busy flag
				if (M_ARESETN == 0) begin
					r_burst_busy <= 1'b0;                                                                            
				end else if (r_burst_addr) begin
					r_burst_busy <= 1'b1;
				end else if (wnext && M_WLAST) begin
					r_burst_busy <= 0;
				end
			end

			assign	w_wvalid	=	(r_burst_busy && M_WREADY) ? !i_fifo_empty : 1'b0;
			assign	M_WLAST		=	(r_burst_count == M_AWLEN) && r_burst_busy;
			// always @(posedge M_ACLK) begin		// write ready signal
			// 	if (M_ARESETN == 0 ) begin
			// 		r_wvalid <= 1'b0;
			// 	end else if (r_burst_busy && M_WREADY) begin
			// 		if (r_wvalid && M_WLAST) begin
			// 			r_wvalid <= 1'b0;
			// 		end else begin
			// 			r_wvalid <= !i_fifo_empty;
			// 		end
			// 	end
			// end
		end
	endgenerate

	// Write Done Flag
	generate
		if (MAX_BURST_LEN == 0) begin
			always @(posedge M_ACLK) begin	// burst read done flag
				if (M_ARESETN == 0) begin
					r_writes_done	<=	1'b0;
				end else if (r_wstate == WRITE_DATA_END ||
								r_wstate == WRITE_END) begin
					r_writes_done	<=	1'b0;
				end else if (wnext) begin
					r_writes_done	<=	1'b1;
				end else begin
					r_writes_done	<=	r_writes_done;
				end
			end
		end else begin
			always @(posedge M_ACLK) begin	// burst write done flag
				if (M_ARESETN == 0) begin
					r_writes_done	<=	1'b0;
				end else if (r_wstate == WRITE_DATA_END ||
								r_wstate == WRITE_END) begin
					r_writes_done	<=	1'b0;
				end else if (wnext && M_WLAST) begin
					r_writes_done	<=	1'b1;
				end else begin
					r_writes_done	<=	r_writes_done;
				end
			end
		end
	endgenerate

	// Write Response
	always @(posedge M_ACLK) begin
		if ( M_ARESETN == 0 ) begin
			r_bready <= 1'b0;
		end else if ( M_BVALID && r_wstate == WRITE_DATA_END ) begin
			r_bready <= 1'b1;
		end else if ( r_bready ) begin
			r_bready <= 1'b0;
		end else begin
			r_bready <= r_bready;
		end
	end
    
endmodule