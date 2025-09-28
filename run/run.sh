set -e  # Exit on any error

rm -rf sim
clear
echo "Start Compiling" 
g++   -Iverilated/obj_dir   -I$SYSTEMC_HOME/include   -I/usr/share/verilator/include   -I/usr/share/verilator/include/vltstd   -L$SYSTEMC_HOME/lib-linux64   -Lverilated/obj_dir   *.cpp   -lVtop -lverilated   -lsystemc -lpthread -lm   -std=c++17 -o sim
echo "Start Simulation"
./sim
rm -rf sim

