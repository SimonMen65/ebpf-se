ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
LIBBPF_DIR:=$(ROOT_DIR)/../../libbpf-stubbed/src
COMMON_DIR:=$(ROOT_DIR)/../common
PIX_DIR:= $(ROOT_DIR)/../..

LLVM_RELEASE=12
LLC=llc-$(LLVM_RELEASE)
CLANG=clang-$(LLVM_RELEASE)
CC := gcc
UNAME_P := $(shell uname -p)
PKG_CONFIG := pkg-config
LIBJSON_PKG_CFLAGS := $(shell $(PKG_CONFIG) --cflags json-c)
LIBJSON_PKG_LIBS := $(shell $(PKG_CONFIG) --static --libs json-c)

XDP_C ?= ${XDP_TARGETS:=.c}
XDP_OBJ = ${XDP_C:.c=.o}

OBJECT_LIBBPF = $(LIBBPF_DIR)/libbpf.a

# Extend if including Makefile already added some
COMMON_OBJS += $(COMMON_DIR)/common_params.o $(COMMON_DIR)/common_user_bpf_xdp.o

# Create expansions for dependencies
COMMON_H := ${COMMON_OBJS:.o=.h}

EXTRA_DEPS +=

# BPF-prog kern and userspace shares struct via header file:
KERN_USER_H ?= $(wildcard common_kern_user.h)

LDFLAGS ?= -L$(LIBBPF_DIR)

BPF_CFLAGS ?= -I$(LIBBPF_DIR)/build/usr/include/ -I$(ROOT_DIR)/../headers/
BPF_CFLAGS += -I /usr/include/$(UNAME_P)-linux-gnu

ifeq ($(REPLAY), 1)
	BPF_CFLAGS += -DREPLAY
endif

clean:
	rm -rf $(LIBBPF_DIR)/build
	$(MAKE) -C $(LIBBPF_DIR) clean
	$(MAKE) -C $(COMMON_DIR) clean
	rm -f $(XDP_OBJ)
	rm -f *.ll *.bc
	rm -f *~

clean-klee:
	rm -rf $(ROOT_DIR)/klee-*
	rm -f $(ROOT_DIR)/res-tree-*
	rm -f $(ROOT_DIR)/neg-tree*

llvm-check: $(CLANG) $(LLC)
	@for TOOL in $^ ; do \
		if [ ! $$(command -v $${TOOL} 2>/dev/null) ]; then \
			echo "*** ERROR: Cannot find tool $${TOOL}" ;\
			exit 1; \
		else true; fi; \
	done

xdp-target: $(XDP_C) Makefile $(KERN_USER_H) $(EXTRA_DEPS)
	$(CLANG) \
		-target bpf \
		-DKLEE_VERIFICATION\
		$(BPF_CFLAGS) \
		-I $(KLEE_INCLUDE) \
		-D__USE_VMLINUX__ \
		-D__TARGET_ARCH_x86 \
		-DBPF_NO_PRESERVE_ACCESS_INDEX \
		-Wall \
		-Wno-unused-value \
		-Wno-unused-variable \
		-Wno-pointer-sign \
		-Wno-compare-distinct-pointer-types \
		-Werror \
		-fno-builtin \
		-O0 -emit-llvm -c -g $(XDP_C)
	# $(LLC) -march=bpf -filetype=obj -o $@ ${@:.o=.ll}

xdp-target-runtest: $(XDP_C) Makefile $(KERN_USER_H) $(EXTRA_DEPS)
	$(CLANG) \
	    -D __BPF_TRACING__ -DKLEE_VERIFICATION -DREPLAY \
		-DOPENED_EQUIVALENCE\
	    $(BPF_CFLAGS) \
		$(LIBJSON_PKG_CFLAGS) \
	    -I $(KLEE_INCLUDE) \
	    -Wall \
	    -Wno-unused-value \
	    -Wno-pointer-sign \
	    -Wno-compare-distinct-pointer-types \
	    -Werror \
	    -fno-builtin \
		-L/klee/build/lib/ \
		$(LIBJSON_PKG_LIBS) \
		-lkleeRuntest \
	    -O2 -o ${XDP_C:.c=.bin} $(XDP_C) 

libbpf:
	cd $(LIBBPF_DIR) && bash build.sh

symbex:
	/usr/bin/time -v \
		klee -kdalloc -kdalloc-heap-start-address=0x00040000000 -kdalloc-heap-size=1 -libc=uclibc --external-calls=all --disable-verify \
		-solver-backend=z3 --exit-on-error -max-memory=750000 -search=dfs $(XDP_TARGETS).bc
