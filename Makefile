#
# This Makefile is used to bootstrap Nu.
# Use it to build "mininush", a simpler and statically-linked
# version of nush, the Nu shell.
#

SYSTEM = $(shell uname)

PCRE_INCLUDE ?= $(shell pcre-config --cflags)
PCRE_LIB ?= $(shell pcre-config --libs)

ifeq ($(SYSTEM), Darwin)
	ifeq ($(shell test -e /usr/lib/libffi.dylib && echo yes), yes)
		# Use the libffi that ships with OS X.
		FFI_LIB = -L/usr/lib -lffi
		FFI_INCLUDE = -I/usr/include/ffi
		LEOPARD_CFLAGS = -DLEOPARD_OBJC2
	else
		# Use the libffi that is distributed with Nu.
		FFI_LIB = -L./libffi -lffi
		FFI_INCLUDE = -I./libffi/include
		LEOPARD_CFLAGS =
	endif

else # GNUstep
	FFI_LIB=-lffi
	FFI_INCLUDE=
endif

INCLUDES = $(FFI_INCLUDE) -I./include

ifeq ($(SYSTEM), Darwin)
	FRAMEWORKS = -framework Cocoa
	INCLUDES += $(PCRE_INCLUDE)
	LIBS = $(PCRE_LIB) -lobjc -lreadline
else
	FRAMEWORKS =
	LIBS = -lm -lpcre -lreadline -lgnustep-base
	LIBDIRS =
endif

C_FILES = $(wildcard objc/*.c)
OBJC_FILES = $(wildcard objc/*.m) $(wildcard main/*.m)
GCC_FILES = $(OBJC_FILES) $(C_FILES)
GCC_OBJS = $(patsubst %.m, %.o, $(OBJC_FILES)) $(patsubst %.c, %.o, $(C_FILES))

CC = gcc
CFLAGS = -g -Wall -DMININUSH -std=gnu99
MFLAGS = -fobjc-exceptions

ifeq ($(SYSTEM), Darwin)
	CFLAGS += -DMACOSX -DDARWIN $(LEOPARD_CFLAGS)
else
#	CFLAGS += -DLINUX
#	MFLAGS += -fconstant-string-class=NSConstantString
	MFLAGS += $(shell gnustep-config --objc-flags)
endif

ifeq ($(SYSTEM), Linux)
	CFLAGS += -DLINUX
endif

ifeq ($(SYSTEM), FreeBSD)
	CFLAGS += -DFREEBSD 
endif

# OpenSolaris "uname" kernel is "SunOS"
ifeq ($(SYSTEM), SunOS)
	CFLAGS += -DOPENSOLARIS
	LIBS += -lcurses
endif

LDFLAGS += $(FRAMEWORKS)
LDFLAGS += $(LIBS)
LDFLAGS += $(LIBDIRS)
LDFLAGS += $(FFI_LIB)
ifeq ($(SYSTEM), Darwin)
else
	LDFLAGS += $(shell gnustep-config --base-libs)
	LDFLAGS += -lobjc 
ifneq ($(SYSTEM), SunOS)
	LDFLAGS += -Wl,--rpath -Wl,/usr/local/lib
endif
endif

all: mininush

%.o: %.m
	$(CC) $(CFLAGS) $(MFLAGS) $(INCLUDES) -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

.PHONY: mininush
mininush: $(GCC_OBJS)
	$(CC) $(GCC_OBJS) -g -O2 -o mininush $(LDFLAGS)

.PHONY: clean
clean:
	rm -f objc/*.o main/*.o

.PHONY: clobber
clobber: clean
	rm -f mininush
