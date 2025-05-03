#!/bin/bash


TODAY=$(date +"%d-%m-%Y")
MODULE_FILE="$1"
MODULE_NAME=$(basename "$MODULE_FILE" .v)
TOP="tb/${MODULE_NAME}_tb.v"
OUT="results/${MODULE_NAME}_tb_${TODAY}.vvp"
VCD="results/${MODULE_NAME}.vcd"

if [ ! -f "$TOP" ]; then
  echo "❌ Testbench not found: $TOP"
  exit 1
fi

# Compile
echo "🔧 Compiling $MODULE_NAME..."
iverilog -o "$OUT" "src/$MODULE_FILE" "$TOP"

# Run
echo "🚀 Running simulation..."
vvp "$OUT"

# Open GTKWave if VCD was generated
if [ -f "$VCD" ]; then
  echo "📊 Opening waveform in GTKWave..."
  gtkwave "$VCD" &
else
  echo "⚠️ No VCD file found. Did you forget to add $dumpfile/$dumpvars?"
fi

