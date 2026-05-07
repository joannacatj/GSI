# Define compilers and options

# CUDA Path
# If CUDA_PATH is not already defined, use the default path
CUDA_PATH = /usr/local/cuda-12.5

# Path to gcc-11
# If GCC_11_PATH is not already defined, use the default path installed by Linuxbrew
GCC_11_PATH = /home/linuxbrew/.linuxbrew/Cellar/gcc@11/11.4.0

# Define the compilers explicitly
CC = $(GCC_11_PATH)/bin/gcc-11
CXX = $(GCC_11_PATH)/bin/g++-11
NVCC = $(CUDA_PATH)/bin/nvcc

# Compilation flags
CFLAGS = -std=c++14 -c -O2 -I$(CUDA_PATH)/include
EXEFLAG = -O2 -shared
LDFLAGS = -L$(CUDA_PATH)/lib64 -lcudart -lcudadevrt #-ldl -lm
INCLUDES = -I$(CUDA_PATH)/include
GPU_ARCHITECTURE = sm_86

# Pybind11 and Python includes
PYBIND11_INCLUDES = $(shell python3 -m pybind11 --includes)
PYTHON_LDFLAGS = $(shell python3-config --ldflags)

# NVCC command
NVCCFLAGS = -arch=$(GPU_ARCHITECTURE) -rdc=true --ptxas-options=-v -Xcompiler -fPIC $(INCLUDES) --compiler-bindir $(GCC_11_PATH)/bin -std=c++14 -c -O2 -I$(CUDA_PATH)/include

# Object directory and files
objdir = ./objs/
objfile = $(objdir)Util.o $(objdir)IO.o $(objdir)Match.o $(objdir)Graph.o $(objdir)isomorphism.o $(objdir)pybind_wrapper.o

# Default target
all: libisomorphism.so isomorphism$(shell python3-config --extension-suffix) GSI.exe

# Link all object files to create the shared object file
libisomorphism.so: $(objfile)
	$(NVCC) -arch=sm_86 -shared -o libisomorphism.so $(objfile) $(LDFLAGS)


# Compile source files into object files
$(objdir)Util.o: util/Util.cpp util/Util.h | $(objdir)
	$(CC) -fPIC $(CFLAGS) util/Util.cpp -o $(objdir)Util.o

$(objdir)Graph.o: graph/Graph.cpp graph/Graph.h | $(objdir)
	$(CC) -fPIC $(CFLAGS) graph/Graph.cpp -o $(objdir)Graph.o

$(objdir)IO.o: io/IO.cpp io/IO.h | $(objdir)
	$(CC) -fPIC $(CFLAGS) io/IO.cpp -o $(objdir)IO.o

$(objdir)Match.o: match/Match.cu match/Match.h | $(objdir)
	$(NVCC) $(NVCCFLAGS) match/Match.cu -o $(objdir)Match.o

$(objdir)isomorphism.o: main/isomorphism.cu main/isomorphism.h | $(objdir)
	$(NVCC) $(NVCCFLAGS) main/isomorphism.cu -o $(objdir)isomorphism.o

$(objdir)run.o: main/run.cu io/IO.h graph/Graph.h match/Match.h util/Util.h | $(objdir)
	$(NVCC) $(NVCCFLAGS) main/run.cu -o $(objdir)run.o

# Ensure the object directory exists
$(objdir):
	mkdir -p $(objdir)

# Pybind11 module
$(objdir)pybind_wrapper.o: pybind_wrapper.cu main/isomorphism.h graph/Graph.h match/Match.h io/IO.h util/Util.h | $(objdir)
	$(NVCC) $(NVCCFLAGS) -Xcompiler -fPIC $(CFLAGS) $(PYBIND11_INCLUDES) pybind_wrapper.cu -o $(objdir)pybind_wrapper.o

isomorphism$(shell python3-config --extension-suffix): $(objdir)pybind_wrapper.o $(objdir)Util.o $(objdir)IO.o $(objdir)Match.o $(objdir)Graph.o $(objdir)isomorphism.o
	$(NVCC) -arch=$(GPU_ARCHITECTURE) -rdc=true --ptxas-options=-v -Xcompiler -fPIC $(INCLUDES) --compiler-bindir $(GCC_11_PATH)/bin -std=c++14 -O2 -I$(CUDA_PATH)/include $(EXEFLAG) -o isomorphism$(shell python3-config --extension-suffix) $(objdir)pybind_wrapper.o $(objdir)Util.o $(objdir)IO.o $(objdir)Match.o $(objdir)Graph.o $(objdir)isomorphism.o $(PYTHON_LDFLAGS) $(LDFLAGS)

GSI.exe: $(objdir)run.o $(objdir)Util.o $(objdir)IO.o $(objdir)Match.o $(objdir)Graph.o
	$(NVCC) -arch=$(GPU_ARCHITECTURE) -rdc=true --ptxas-options=-v -Xcompiler -fPIC $(INCLUDES) --compiler-bindir $(GCC_11_PATH)/bin -std=c++14 -O2 -I$(CUDA_PATH)/include -o GSI.exe $(objdir)run.o $(objdir)Util.o $(objdir)IO.o $(objdir)Match.o $(objdir)Graph.o $(LDFLAGS)


# Phony targets 
.PHONY: clean dist tarball test sumlines doc

clean:
	rm -f $(objdir)*

dist: clean
	rm -f *.txt *.exe *.so *.cpython-*.so
	rm -f *.g
	rm -f cuda-memcheck.*

tarball:
	tar -czvf gsi.tar.gz main util match io graph Makefile README.md objs

sumlines:
	bash script/sumline.sh

doc:
	doxygen
