# ====================================
# File: test_uart_rx.py
# Author: jaimebw
# Created: 2025-05-04 22:06:58
# ====================================

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb_test.simulator import run
from pathlib import Path
import sys
sys.path.append(str(Path(__file__).resolve().parent))
COCOTB_RESOLVE_X = 1


# Parameters
CLK_FREQ = 50_000_000
BAUD_RATE = 9600
CLKS_PER_BIT = CLK_FREQ // BAUD_RATE
MID_BIT= CLKS_PER_BIT// 2
BIT_TIME_NS = CLKS_PER_BIT * 20  # 20ns per clock tick at 50MHzk
FRAME_BITS =8 


START_BIT = 0
STOP_BIT  = 1

async def run_cycles(dut, n):
    for _ in range(n):
        await RisingEdge(dut.clk)


async def watch_rx_done(dut):
    for _ in range(100_000):
        await RisingEdge(dut.clk)
        if dut.rx_done.value == 1:
            print("rx_done detected!")
            return
    assert False, "rx_done was never asserted"

@cocotb.test()
async def uart_rx_test(dut):
    """Receive 0xAA (1010_1010) and check rx_done / rx_data"""

    # ----------------------------------------------------------------
    # Create 50 MHz clock
    # ----------------------------------------------------------------
    clock = Clock(dut.clk, 20, units="ns")  # 50 MHz
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0

    await RisingEdge(dut.clk)
    dut.rx.value  = 1                 # line idle

    # ----------------------------------------------------------------
    # Build the UART frame: start + 8 data + stop
    # LSB first for UART
    # ----------------------------------------------------------------
    data_byte = 0xAA                  # 1010_1010
    frame_bits = [(data_byte >> i) & 1 for i in range(FRAME_BITS)]
    await Timer(BIT_TIME_NS, units="ns")

    assert dut.rx_busy.value == 0 
    assert dut.rx_done.value == 0
    dut.rx.value  = 0                 # line idle

    await Timer(BIT_TIME_NS, units="ns")
    assert dut.rx_busy.value == 1

    rx_done_task = cocotb.start_soon(watch_rx_done(dut))
    for index, bit in enumerate(frame_bits):
        dut.rx.value  = bit                 # line idle
        assert dut.rx_data.value == 0
        await Timer(BIT_TIME_NS, units="ns")

    assert dut.rx_data.value != 0



    # ----------------------------------------------------------------
    # Assertions
    # ----------------------------------------------------------------
    assert dut.rx_busy.value == 0,  "rx_busy should be low after frame"
    assert dut.rx_data.value.integer == data_byte, \
        f"Expected 0x{data_byte:02X}, got 0x{dut.rx_data.value.integer:02X}"




def test_uart_rx_runner():
    """Run simulation for UartRx"""
    this_dir = Path(__file__).resolve().parent
    rtl_file = this_dir.parent / "src" / "uart_rx.v"
    mod_name = Path(__file__).stem

    assert rtl_file.exists(), f"Missing Verilog source: {rtl_file}"

    run(
        verilog_sources=[rtl_file],
        toplevel="UartRx",
        module= mod_name,
        parameters={"FRAME_BITS": FRAME_BITS},
        waves=True,
        sim_build=this_dir / f"sim_{mod_name}",
        timescale="1ns/1ps"
    )

