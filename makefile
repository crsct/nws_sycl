gpu: 
	acpp -g -march=native -O3 -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 -Wcast-align -Wconversion -Wsign-conversion -Wnull-dereference src/nws.cc -o ./build/output
cuda: 
	acpp -g -march=native --acpp-targets='cuda:sm_60' -O3 -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 -Wcast-align -Wconversion -Wsign-conversion -Wnull-dereference src/nws.cc -o ./build/output
