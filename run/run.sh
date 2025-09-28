#!/bin/bash
# verilateRTL.sh
# Converts RTL in ./rtl/ to Verilated SystemC in ./verilated/

set -e  # Exit on any error

# Directories
RTL_DIR="rtl"
TEMP_DIR="verilated/obj_dir"
OUTPUT_DIR="verilated"
VERILATOR_INCLUDE="/usr/share/verilator/include"

# Check if RTL files exist
if [ ! -f "$RTL_DIR/MiniALU.sv" ] || [ ! -f "$RTL_DIR/top.sv" ]; then
    echo "❌ Error: Missing RTL files in $RTL_DIR/"
    echo "Expected: MiniALU.sv, top.sv"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run Verilator
echo "🔧 Verilating RTL..."
verilator \
  --cc \
  --sc \
  --build \
  -j \
  -Wall \
  --trace \
  --Mdir "$OUTPUT_DIR/obj_dir" \
  --top-module top \
  "$RTL_DIR/top.sv" \
  "$RTL_DIR/MiniALU.sv" \
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

# python3 generate_transactor.py verilated/obj_dir/Vtop.h transactor.h
python3 run/generate_custom_data.py verilated/obj_dir/Vtop.h custom_data.h json_template.json
python3 run/generate_transactor_comparetor.py verilated/obj_dir/Vtop.h transactor.h comparator.h output_struct.h
python3 run/generate_rand_const.py verilated/obj_dir/Vtop.h rand_const.h rand_const.cpp
echo "Run for the first time:"

rm -rf sim
clear
echo "Start Compiling" 
g++   -Iverilated/obj_dir   -I$SYSTEMC_HOME/include   -I/usr/share/verilator/include   -I/usr/share/verilator/include/vltstd   -L$SYSTEMC_HOME/lib-linux64   -Lverilated/obj_dir   *.cpp   -lVtop -lverilated   -lsystemc -lpthread -lm   -std=c++17 -o sim
echo "Start Simulation"
./sim
rm -rf sim

