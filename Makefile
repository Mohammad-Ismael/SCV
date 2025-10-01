.PHONY: clean run verilate

clean:
	rm -rf verilated comparator.h custom_data.h output_struct.h rand_const.* transactor.h coverage_collector.h *.log synth_report

run:
	bash run/run.sh

verilate:
	bash run/verilate.sh

synth:
	bash run/synthesize.sh

