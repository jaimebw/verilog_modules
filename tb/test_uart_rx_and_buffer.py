# ====================================
# File: test_uart_rx_and_buffer.py
# Author: jaimebw
# Created: 2025-05-11 20:15:41
# ====================================

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb_test.simulator import run
from pathlib import Path
import sys
sys.path.append(str(Path(__file__).resolve().parent))


# Parameters
FILE = "uart_tx_and_buffer.v"
CLK_FREQ = 50_000_000
BAUD_RATE = 9600
CLKS_PER_BIT = CLK_FREQ // BAUD_RATE
MID_BIT= CLKS_PER_BIT// 2
BIT_TIME_NS = CLKS_PER_BIT * 20  # 20ns per clock tick at 50MHzk
FRAME_BITS =8 


START_BIT = 0
STOP_BIT  = 1
START_FRAME = 0xAA
END_FRAME = 0x55
TEST_PID = 0x69

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
async def uart_rx_and_pid_normal_mode(dut):

    clock = Clock(dut.clk, 20, units="ns")  # 50 MHz
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    dut.rx.value  = 1                 

    # ----------------------------------------------------------------
    # Build the UART frame: start + 8 data + stop
    # LSB first for UART
    # ----------------------------------------------------------------
    # Generat the whole data input
    pids = [0x10,0x11,0x12,0x13,0x20,0x21,0x22,0x23]
    frames = [] 
    for pid_n,pid in enumerate(pids):
        data_bytes = [START_FRAME,pid,0xF1+pid_n, END_FRAME]
        frames.append(data_bytes)

    for frame_n, data_bytes in enumerate(frames):
        for byte_n, data_byte in enumerate(data_bytes):
            frame_bits = [(data_byte >> i) & 1 for i in range(FRAME_BITS)]
            dut.rx.value  = 0                 
            await Timer(BIT_TIME_NS, units="ns")
            for bit_n, bit in enumerate(frame_bits):
                dut.rx.value  = bit                 # line idle
                await Timer(BIT_TIME_NS, units="ns")

            print(f"Frame number: {frame_n}\tIteration Number: {byte_n}\tByte sent : {hex(data_byte)}")
            dut.rx.value = 1
            await Timer(BIT_TIME_NS, units="ns")
            assert dut.rx_data.value == data_byte
            assert dut.rx_busy.value == 0,  "rx_busy should be low after frame"
            await Timer(BIT_TIME_NS, units="ns")
    assert dut.test.value == 0
    print(f"A1: {hex(dut.a1.value.integer)}\t A2: {hex(dut.a2.value.integer)}")
    assert dut.a1.value == 0xF1F2F3F4
    assert dut.a2.value == 0xF5F6F7F8

@cocotb.test()
async def uart_rx_and_pid_test_mode(dut):

    clock = Clock(dut.clk, 20, units="ns")  # 50 MHz
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    dut.rx.value  = 1                 

    # ----------------------------------------------------------------
    # Build the UART frame: start + 8 data + stop
    # LSB first for UART
    # ----------------------------------------------------------------
    data_bytes = [START_FRAME,TEST_PID,0xF1, END_FRAME]
    for byte_n, data_byte in enumerate(data_bytes):
        frame_bits = [(data_byte >> i) & 1 for i in range(FRAME_BITS)]
        dut.rx.value  = 0                 
        await Timer(BIT_TIME_NS, units="ns")
        for bit_n, bit in enumerate(frame_bits):
            dut.rx.value  = bit                 # line idle
            await Timer(BIT_TIME_NS, units="ns")

        print(f"Iteration Number: {byte_n} Byte sent : {hex(data_byte)}")
        dut.rx.value = 1
        await Timer(BIT_TIME_NS, units="ns")
        assert dut.rx_data.value == data_byte
        assert dut.rx_busy.value == 0,  "rx_busy should be low after frame"
        await Timer(BIT_TIME_NS, units="ns")

    assert dut.test.value ==1 
    assert dut.a1.value == 0xF1
    assert dut.a2.value == 0xF1






def test_uart_rx_runner():
    """Run simulation for UartRx"""
    this_dir = Path(__file__).resolve().parent
    rtl_file = this_dir.parent / "src" / FILE
    mod_name = Path(__file__).stem

    assert rtl_file.exists(), f"Missing Verilog source: {rtl_file}"

    run(
        toplevel="UartTxAndPidBuffer",
        module= mod_name,
        verilog_sources = [
            rtl_file,
            rtl_file.parent/"uart_rx_pid_buffer.v",
            rtl_file.parent/"uart_rx.v",
            ],
        #parameters={"FRAME_BITS": FRAME_BITS},
        waves=True,
        sim_build=this_dir / f"sim_{mod_name}",
        timescale="1ns/1ps"
    )

