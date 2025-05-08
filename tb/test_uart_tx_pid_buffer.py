# ====================================
# File: test_uart_tx_pid_buffer.py
# Author: jaimebw
# Created: 2025-05-05 21:36:24
# ====================================


import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ReadOnly
from cocotb_test.simulator import run
from pathlib import Path
import sys
sys.path.append(str(Path(__file__).resolve().parent))


# Parameters

START_DEL= 0xAA
END_DEL = 0x55
DATA_PID = 0x69

def pack_val(byte_list):
    result = 0
    for i, byte in enumerate(byte_list):
        result |= byte << (8 * i)
    return result
# ======================================================================
# Main test: send one normal-mode frame and verify its bytes.
# ======================================================================
@cocotb.test()
async def operationNormal_mode(dut):
    """Verify START, PID, 4 data bytes, END in normal (DATA_PID) mode."""
    START_DEL, DATA_PID, END_DEL = 0xAA, 0x69, 0x55
    VALUES_TO_PACK =[ 0xA1,0xBE,0x12,0xC1]
    VALUE = pack_val(VALUES_TO_PACK)

    # 50-MHz free-running clock
    cocotb.start_soon(Clock(dut.clk, 20, units="ns").start())
    # Recuerda iniciar todo.... o te salen cosas raras
    dut.rst.value      = 1
    dut.test.value      =0 
    dut.tx_valid.value = 0
    dut.tx_busy.value  = 1                      # UART busy during reset
    await RisingEdge(dut.clk)
    dut.rst.value      = 0
    await RisingEdge(dut.clk)

    # Load the value into the buffer

    dut.tx_valid.value = 1
    dut.tx_float.value = VALUE
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.tx_valid.value = 0 # Not accepting another data input for now ofc
    # Start the reading circle
    sent = []
    for i in range(7):
        # Primer cicle S_LOAD
        dut.tx_busy.value = 1
        await RisingEdge(dut.clk)
        sent.append(dut.tx_data.value)
        print(f"Iteration {i} Value: {dut.tx_data.value}")
        assert dut.tx_start.value == 1
        #
        await RisingEdge(dut.clk)
        assert dut.tx_start.value == 0
        dut.tx_busy.value = 0
        # Son dos ciclos de reloj lo que necesito aqui jeje
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)



    print(sent)
    assert sent[0] == START_DEL
    assert sent[6] == END_DEL
    assert sent[1] == DATA_PID
    assert sent[2] == VALUES_TO_PACK[0]
    assert sent[3] == VALUES_TO_PACK[1]
    assert sent[4] == VALUES_TO_PACK[2]
    assert sent[5] == VALUES_TO_PACK[3]



def test_uart_tx_pid_buffer_runner():
    """Run simulation for UartRx"""
    this_dir = Path(__file__).resolve().parent
    rtl_file = this_dir.parent / "src" / "uart_tx_pid_buffer.v"
    mod_name = Path(__file__).stem

    assert rtl_file.exists(), f"Missing Verilog source: {rtl_file}"

    run(
        verilog_sources=[rtl_file],
        toplevel="UartTxPidBuffer",
        module= mod_name,
        waves=True,
        sim_build=this_dir / f"sim_{mod_name}",
        timescale="1ns/1ps",
        clean = True
    )

