rm -rf synth_report
mkdir synth_report
yosys -q -l synth_report/synth.log -s run/synth.tcl