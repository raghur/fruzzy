.DEFAULT_GOAL := all
ifdef WINDIR
	extn=pyd
else
	extn=so
endif

src = rplugin/python3
test = rplugin
relopt = -d:release -d:removelogger
infoopt = -d:release
native = FUZZY_CMOD=1
win = --os:windows --cpu:amd64 --out:fruzzy_mod.pyd
macos = --os:macosx --cpu:amd64 --out:fruzzy_mod_mac.so
binary=fruzzy_mod.$(extn)

build-debug:
	cd $(src) && \
		nim c --app:lib --out:$(binary) $(infoopt)  fruzzy_mod

build:
	cd $(src) && \
		nim c --app:lib --out:$(binary) $(relopt) fruzzy_mod

debug-single: build-debug
	@echo Testing native mod with minimal file
	cd $(test) && \
	python3 qc-single.py

debug-native: build-debug
	cd $(test) && \
	$(native) python3 qc-fast.py

debug:
	cd $(test) && \
	python3 qc-fast.py

test-py:
	cd $(test) && \
	pytest

test-native: build
	cd $(test) && \
	$(native) pytest


test: test-py test-native

macos:
	cd $(src) && \
		nim c --app:lib $(macos) $(relopt) fruzzy_mod
win:
ifndef WINDIR
	cd $(src) && \
		nim c --app:lib $(win) $(relopt) fruzzy_mod
endif

rel:
	@echo "container image: https://github.com/miyabisun/docker-nim-cross"
	@echo
	docker run -it --rm -v `pwd`:/usr/local/src nim-cross \
		/bin/bash -c "nimble install -y binaryheap nimpy && make cross"

all: test build

# this goal should be run inside docker container
cross: macos win build
	ls -al $(src)/fruzzy_mod*
