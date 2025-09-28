.PHONY: clean run

clean:
	rm -rf verilated comparator.h custom_data.h output_struct.h rand_const.* transactor.h

run:
	bash run/run.sh
