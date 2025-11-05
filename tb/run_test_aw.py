from cocotb_test.simulator import run
def test_run():
	run(
		verilog_sources=[
			"tb_write.v",
			"../axi_write_base.v"
		],
		toplevel="tb_axi_mw",
		module="test_aw",
	)