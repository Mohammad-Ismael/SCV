# ==================================================
# Yosys Synthesis Script
# Top module: rtl
# RTL source: ./rtl/rtl.sv
# Output directory: ./synth_report/
# ==================================================

# ----------------------------
# CONFIGURATION
# ----------------------------
# Choose ONE library by uncommenting the desired line:

# liberty_file = ./synthesis_lib/NangateOpenCellLibrary_typical.lib


# ----------------------------
# SETUP OUTPUT DIR
# ----------------------------
# Yosys doesn't auto-create dirs, so ensure synth_report exists (create manually or via shell)
# mkdir -p synth_report   <-- run this in your shell before Yosys if needed


# ----------------------------
# READ LIBRARY & RTL
# ----------------------------
read_liberty -lib ./synthesis_lib/NangateOpenCellLibrary_typical.lib
read -sv ./rtl/rtl.sv



# ----------------------------
# HIERARCHY & GENERIC SYNTHESIS
# ----------------------------
hierarchy -check -top rtl
proc
opt
fsm
opt
memory -nomap  # keep as generic mem unless you have RAM models
opt

synth -top rtl -flatten
opt -purge

# ----------------------------
# TECHNOLOGY MAPPING
# ----------------------------
dfflibmap -liberty ./synthesis_lib/NangateOpenCellLibrary_typical.lib
opt
abc -liberty ./synthesis_lib/NangateOpenCellLibrary_typical.lib
clean -purge

# ----------------------------
# OUTPUT NETLIST
# ----------------------------
write_verilog ./synth_report/rtl_netlist.v

# ----------------------------
# REPORTING
# ----------------------------
stat -liberty ./synthesis_lib/NangateOpenCellLibrary_typical.lib -top rtl
tee -o ./synth_report/area.rpt stat -liberty ./synthesis_lib/NangateOpenCellLibrary_typical.lib

# ----------------------------
# DEBUG & VISUALIZATION (optional but useful)
# ----------------------------
write_json    ./synth_report/rtl_synth.json
write_rtlil   ./synth_report/rtl.il
show -format dot -prefix ./synth_report/rtl
show -format png -prefix ./synth_report/rtl_schematic -viewer none

# Final stat for log
stat