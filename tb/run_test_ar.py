from cocotb_test.simulator import run
def test_run():
	run(
		verilog_sources=[
			"tb_read.v",
			"../axi_read_base.v"
		],
		toplevel="tb_axi_mr",
		module="test_ar",
	)