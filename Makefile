#	need libmono.so copy to /usr/lib/
#	if you lib in curdir you can exec LD_LIBRARY_PATH=. ./monogo
#	make or make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- DEF_BOARD=-DXJGW1000_BOARD
#   or make ARCH=arm CROSS_COMPILE=arm-linux- DEF_BOARD=-DXJGW1000_BOARD
# 	you need select DEF_BOARD can XJGW1000_BOARD MONO16_BOARD 
# 	you can "make install DEF_BOARD=-DXJGW1000_BOARD" or "make install INST_DIR_F:=/home/n9/release/applte/xjgw/apps"
#   -make install INST_DIR_F:=/usr/local/arm_linux_9.3/bin/../arm-xjgw-linux-uclibcgnueabi/sysroot 
#   you can "make strip ARCH=arm CROSS_COMPILE=arm-linux-" 
#

CROSS_COMPILE=arm-linux-
ARCH:=arm

CFLAG=-Wall
NDEBUG=-DNDEBUG

CFLAG += $(DEF_BOARD)

CC:=$(CROSS_COMPILE)gcc
LD:=$(CROSS_COMPILE)ld
STRIP:=$(CROSS_COMPILE)strip

ifeq  ($(DEF_BOARD), -DXJGW1000_BOARD)
 INST_DIR_F:=/home/n9/release/applte/xjgw/apps
endif
ifeq  ($(DEF_BOARD), -DXJGW800_BOARD)
 INST_DIR_F:=/home/n9/release/applte/xjgw/apps_gw800
endif
ifeq  ($(DEF_BOARD), -DXJGW600_BOARD)
 INST_DIR_F:=/home/n9/release/applte/xjgw/apps_gw600
endif
ifeq  ($(DEF_BOARD), -DMONO16_BOARD)
 INST_DIR_F:=/home/v3s/release/applte/v3s/mono_other
 INST_DIR_U:=/home/v3s/release/applte/v3s_update/mono_app
endif

PKGC ?= pkg-config

LUAPKG ?= lua lua5.1 lua5.2 lua5.3
# lua's package config can be under various names
LUAPKGC := $(shell for pc in $(LUAPKG); do \
		$(PKGC) --exists $$pc && echo $$pc && break; \
	done)

LUA_VERSION := $(shell $(PKGC) --variable=V $(LUAPKGC))
LUA_LIBDIR := $(shell $(PKGC) --variable=libdir $(LUAPKGC))
LUA_CFLAGS := $(shell $(PKGC) --cflags $(LUAPKGC))
LUA_LDFLAGS := $(shell $(PKGC) --libs-only-L $(LUAPKGC))

CMOD = libmodbus.so
OBJS = lua-libmodbus.o
LIBS = -lmodbus
CSTD = -std=c11

OPT ?= -Os
WARN = -Wall -pedantic
CFLAGS += -g -fPIC $(CSTD) $(WARN) $(OPT) $(LUA_CFLAGS) $(EXTRA_CFLAGS)
LDFLAGS += -shared $(CSTD) $(LIBS) $(LUA_LDFLAGS) $(EXTRA_LDFLAGS)

ifeq ($(OPENWRT_BUILD),1)
LUA_VERSION=
endif

all: $(CMOD)

$(CMOD): $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) $(LIBS) -o $@

.c.o:
	$(CC) -c $(CFLAGS) -o $@ $<

clean:
	$(RM) $(CMOD) $(OBJS)

test:
	busted --exclude-tags real

strip:
	$(STRIP) -s $(CMOD)

# Convenience targets 
ALL= all
STRIP_D= strip

install:
	$(MAKE) $(ALL)
	$(MAKE) $(STRIP_D)
	mkdir -p $(INST_DIR_F)/usr/lib/lua/$(LUA_VERSION)
	cp -rf $(CMOD) $(INST_DIR_F)/usr/lib/lua/$(LUA_VERSION)
