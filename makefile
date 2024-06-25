all: 
	acpp -g -O3 -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 -Wcast-align -Wconversion -Wsign-conversion -Wnull-dereference src/nws.cc -o ./build/output
