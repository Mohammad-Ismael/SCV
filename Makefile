.PHONY: clean run verilate

clean:
	rm -rf verilated comparator.h custom_data.h output_struct.h rand_const.* transactor.h coverage_collector.h *.log

run:
	bash run/run.sh

verilate:
	bash run/verilate.sh
