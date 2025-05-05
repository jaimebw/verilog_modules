# ====================================
# File: test_uart_tx.py
# Author: jaimebw
# Created: 2025-05-04 16:00:16
# ====================================
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb_test.simulator import run
from pathlib import Path
import sys
sys.path.append(str(Path(__file__).resolve().parent))


# Parameters
CLK_FREQ = 50_000_000
BAUD_RATE = 9600
CLKS_PER_BIT = CLK_FREQ // BAUD_RATE
BIT_TIME_NS = CLKS_PER_BIT * 20  # 20ns per clock tick at 50MHzk
FRAME_BITS = 10


@cocotb.test()
async def uart_tx_test(dut):
    """Test UART TX emits correct bitstream for 0xAA"""
    clock = Clock(dut.clk, 20, units="ns")  # 50 MHz
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0

    await RisingEdge(dut.clk)

    # Send a known frame: start(0), 0xAA (10101010), stop(1)
    #frame = 0x3FF # Funny, it is always one...
    frame = 0b0_10101010_1
    dut.frame_data.value = frame
    dut.tx_start.value = 0

    await Timer(20, units="ns")  # Give it a short pulse
    dut.tx_start.value = 1

    bits = [(frame >> i) & 1 for i in range(FRAME_BITS)]
    test_rest = 0;

    for i, expected in enumerate(bits):
        await Timer(BIT_TIME_NS, units="ns")
        actual = dut.tx.value.integer
        test_rest |= actual << i
        print(f"Bit {i}: expected {expected}, got {actual}")
        assert actual == expected
    



def test_uart_tx_runner():
    """Run simulation for UartTx"""
    this_dir = Path(__file__).resolve().parent
    rtl_file = this_dir.parent / "src" / "uart_tx.v"

    assert rtl_file.exists(), f"Missing Verilog source: {rtl_file}"

    run(
        verilog_sources=[rtl_file],
        toplevel="UartTx",
        module=Path(__file__).stem,
        parameters={"FRAME_BITS": 10},
        waves=True,
        sim_build=this_dir / "sim_build",
        timescale="1ns/1ps"
    )

