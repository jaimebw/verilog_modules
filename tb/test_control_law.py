# ====================================
# File: test_control_law.py
# Author: jaimebw
# Created: 2025-05-08 21:48:04
# ====================================

import cocotb
from cocotb.triggers import ReadOnly
from cocotb_test.simulator import run
from pathlib import Path
import sys
sys.path.append(str(Path(__file__).resolve().parent))


TEST_VAL = 1 <<16

@cocotb.test()
async def control_law(dut):
    # Test the normal operation
    dut.test.value = 0
    dut.a1.value = TEST_VAL 
    dut.a2.value = TEST_VAL
    await ReadOnly()
    assert dut.b.value == 2*TEST_VAL

@cocotb.test()
async def control_law_test(dut):
    # Test the test mode in the control law
    dut.test.value = 1
    dut.a1.value = TEST_VAL 
    dut.a2.value = TEST_VAL

    await ReadOnly()

    assert dut.b.value == 0x2 <<16








def test_control_law():
    """Run simulation for UartRx"""
    this_dir = Path(__file__).resolve().parent
    rtl_file = this_dir.parent / "src" / "control_law.v"
    mod_name = Path(__file__).stem

    assert rtl_file.exists(), f"Missing Verilog source: {rtl_file}"

    run(
        verilog_sources=[rtl_file],
        toplevel="LandauControlLaw",
        module= mod_name,
        parameters={
               "K1": "32'sd65536", # 1.0
                "K2": "32'sd65536" # 1.0
        },
        waves=True,
        sim_build=this_dir / f"sim_{mod_name}",
        timescale="1ns/1ps"
    )

