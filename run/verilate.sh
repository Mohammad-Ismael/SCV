#!/bin/bash
# verilateRTL.sh
# Converts RTL in ./rtl/ to Verilated SystemC in ./verilated/
set -e  # Exit on any error
# Directories
RTL_DIR="rtl"
TEMP_DIR="verilated/obj_dir"
OUTPUT_DIR="verilated"
VERILATOR_INCLUDE="/usr/share/verilator/include"
# # Check if RTL files exist
# if [ ! -f "$RTL_DIR/rtl.sv" ] || [ ! -f "$RTL_DIR/top.sv" ]; then
#     echo "❌ Error: Missing RTL files in $RTL_DIR/"
#     echo "Expected: rtl.sv, top.sv"
#     exit 1
# fi
# Create output directory
mkdir -p "$OUTPUT_DIR"
# Run Verilator
echo "🔧 Verilating RTL..."
verilator \
  --cc \
  --sc \
  --build \
  -j \
  --timing \
  --Wno-fatal  \
  -Wall \
  --trace \
  --Mdir "$OUTPUT_DIR/obj_dir" \
  --top-module top \
  "$RTL_DIR/clk_rst_controller.sv" \
  "$RTL_DIR/dec.sv" \
  "$RTL_DIR/exu.sv" \
  "$RTL_DIR/ifu.sv" \
  "$RTL_DIR/main_memory.sv" \
  "$RTL_DIR/riscv_processor_tb.sv" \
  "$RTL_DIR/riscv_processor.sv" \
  "$RTL_DIR/wb.sv" \
  -CFLAGS "-std=c++17"
# cp "$TEMP_DIR/Vtop.h" ./
# cp "$TEMP_DIR/Vtop.cpp" ./
# cp "$TEMP_DIR/Vtop__pch.h" ./
# cp "$TEMP_DIR/Vtop__Syms.h" ./
# mv ./Vtop.cpp ./rtl.cpp
# mv ./Vtop.h ./rtl.h
# rm -rf verilated
echo "✅ Verilation complete! Output in: $OUTPUT_DIR/obj_dir/"
echo ""
echo "To compile with SystemC, use these flags:"
echo "  -I$OUTPUT_DIR/obj_dir"
echo "  -I$VERILATOR_INCLUDE"
echo "  -I$VERILATOR_INCLUDE/vltstd"
echo "  -L$OUTPUT_DIR/obj_dir"
echo "  -lVtop -lverilated"
python3 run/generate_custom_data.py verilated/obj_dir/Vtop.h custom_data.h json_template.json
python3 run/generate_transactor_comparetor.py verilated/obj_dir/Vtop.h transactor.h comparator.h output_struct.h
python3 run/generate_rand_const.py verilated/obj_dir/Vtop.h rand_const.h rand_const.cpp
python3 run/generate_dummy_rm.py output_struct.h ./
echo "Run for the first time:"
bash run/run.sh