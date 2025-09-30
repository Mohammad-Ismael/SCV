#!/bin/bash
set -e  # Exit on any error

# Clean previous binary
rm -rf sim
clear

# Dynamically locate the header
VERILATED_SC_DIR=$(find /usr -name "verilated_sc.h" -print -quit 2>/dev/null | xargs dirname)

if [ -z "$VERILATED_SC_DIR" ]; then
    echo "Error: verilated_sc.h not found under /usr"
    exit 1
fi

echo "Start Compiling"
g++ \
    -Iverilated/obj_dir \
    -I"$SYSTEMC_HOME/include" \
    -I/usr/share/verilator/include \
    -I/usr/share/verilator/include/vltstd \
    -I"$VERILATED_SC_DIR" \
    -L"$SYSTEMC_HOME/lib-linux64" \
    -Lverilated/obj_dir \
    *.cpp \
    -lVtop -lverilated -lsystemc -lpthread -lm \
    -std=c++17 -o sim

echo "Start Simulation"
./sim

rm -rf sim
