import cocotb
import cocotbext.axi as axi
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_aw(dut):
	"""Test AW channel functionality"""

	# Create AXI master
	#axi_s = axi.AxiSlave(axi.AxiBus.from_prefix(dut, "M_AXI"), dut.M_ACLK, reset_n=dut.M_ARESETN)

	# Start clock
	cocotb.start_soon(Clock(dut.M_ACLK, 10, units="ns").start())

	dut.i_wstart.value = 0
	dut.i_fixed_burst.value = 1
	dut.M_ARESETN.value = 0
	await Timer(50, units="ns")
	dut.M_ARESETN.value = 1
	await RisingEdge(dut.M_ACLK)

	bus = axi.AxiBus.from_prefix(dut, "M_AXI")

	# AxiSlave生成（Master側とつなぐ）
	axi_slave = axi.AxiRam(bus, dut.M_ACLK, dut.M_ARESETN, size=4096, reset_active_level=False)

	# スレーブの内部メモリを初期化（任意のパターン）
	for addr in range(0, 1024, 4):
		axi_slave.mem[addr:addr+4] = (addr.to_bytes(4, "little"))
	cocotb.log.info("AXI Slave memory initialized.")

	# Reset DUT
	dut.i_start_address.value = 0x0
	dut.i_write_size.value = 1024 + 128  # 1KB + 128B
	dut.M_ARESETN.value = 0
	await Timer(20, units="ns")
	dut.M_ARESETN.value = 1
	await RisingEdge(dut.M_ACLK)
	await RisingEdge(dut.M_ACLK)

	dut.i_wstart.value = 1

	# Wait for some time to allow processing
	await Timer(15001, units="ns")

	dut.i_wstart.value = 0

	await Timer(199, units="ns")

	# Here you would typically check the results of the read operation
	# For example, verify data received matches expected values