sycl: 	
	syclcc -g -march=native --hipsycl-targets='omp;cuda:sm_60;cuda:sm_70' --hipsycl-cuda-path=$(CUDA_PATH) -O3 -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 -Wcast-align -Wconversion -Wsign-conversion -Wnull-dereference src/nws.cc -o ./build/output

acpp:
	acpp -g -march=native --acpp-targets='generic' --acpp-cuda-path=$(CUDA_PATH) -O3 -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 -Wcast-align -Wconversion -Wsign-conversion -Wnull-dereference src/nws.cc -o ./build/output
