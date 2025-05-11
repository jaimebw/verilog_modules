# ====================================
# File: test_uart_rx_pid_buffer.py
# Author: jaimebw
# Created: 2025-05-05 21:35:46
# ====================================

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb_test.simulator import run
from pathlib import Path
import sys
sys.path.append(str(Path(__file__).resolve().parent))


# Parameters

TEST_PID = 0x69
TEST_VAL = 0x2
START_FRAME = 0xAA
END_FRAME = 0x55


async def send_byte(dut,pid_or_data):
    # drive a single byte into dut.rx_byte, pulsing rx_done for 1 cycle
    dut.rx_byte.value = pid_or_data
    dut.rx_done.value = 1
    await RisingEdge(dut.clk)
    dut.rx_done.value = 0
    await RisingEdge(dut.clk)


async def wath_ready(dut):
    for _ in range(10):
        await RisingEdge(dut.clk)
        if dut.ready.value ==1:
            return
    assert False
        


@cocotb.test()
async def operationTest_mode(dut):
    """ Test the buffer when running in test mode"""
    cocotb.start_soon(Clock(dut.clk, 20, units="ns").start())
    ready_flag = cocotb.start_soon(wath_ready(dut))

    # reset
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    # send A1 bytes: PID then data for each byte
    #for pid in [TEST_PID]:
    #await send_byte(dut, clk, TEST_PID)
    await send_byte(dut,  START_FRAME)
    await send_byte(dut,  TEST_PID)
    await send_byte(dut,  TEST_VAL)
    await send_byte(dut,  END_FRAME)

    # give DUT one extra cycle to assert ready
    await RisingEdge(dut.clk)
    #assert dut.ready.value == 1, f"ready was {int(dut.ready.value)}"
    assert dut.test.value  == 1, f"test was {int(dut.test.value)}"
    assert dut.a1.value    ==  TEST_VAL
    assert dut.a1.value    ==  dut.a2.value
    await ready_flag

@cocotb.test()
async def operationNormal_mode(dut):
    """ Test the buffer when running a norma control law"""
    cocotb.start_soon(Clock(dut.clk, 20, units="ns").start())
    ready_flag = cocotb.start_soon(wath_ready(dut))

    # reset
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    # send A1 bytes: PID then data for each byte
    for pid in [0x10, 0x11, 0x12, 0x13]:
        await send_byte(dut,  START_FRAME)
        await send_byte(dut,  pid)
        await send_byte(dut,  0x01)
        await send_byte(dut,  END_FRAME)

    # send A2 bytes
    for pid in [0x20, 0x21, 0x22, 0x23]:
        await send_byte(dut,  START_FRAME)
        await send_byte(dut,  pid)
        await send_byte(dut,  0x01)
        await send_byte(dut,  END_FRAME)

    # give DUT one extra cycle to assert ready
    await RisingEdge(dut.clk)

    #assert dut.ready.value == 1, f"ready was {int(dut.ready.value)}"
    assert dut.a1.value    == 0x01010101, f"a1 = {hex(int(dut.a1.value))}"
    assert dut.a2.value    == 0x01010101, f"a2 = {hex(int(dut.a2.value))}"
    assert dut.test.value  == 0, f"test was {int(dut.test.value)}"
    await ready_flag




def test_uart_rx_pid_buffer_runner():
    """Run simulation for UartRx"""
    this_dir = Path(__file__).resolve().parent
    rtl_file = this_dir.parent / "src" / "uart_rx_pid_buffer.v"
    mod_name = Path(__file__).stem

    assert rtl_file.exists(), f"Missing Verilog source: {rtl_file}"

    run(
        verilog_sources=[rtl_file],
        toplevel="UartRxPidBuffer",
        module= mod_name,
        waves=True,
        sim_build=this_dir / f"sim_{mod_name}",
        timescale="1ns/1ps"
    )

