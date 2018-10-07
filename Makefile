.DEFAULT_GOAL := all

src = rplugin/python3
relopt = -d:release -d:removelogger
infoopt = -d:release
native = FUZZY_CMOD=1
win = --os:windows --cpu:amd64 --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc

build-debug:
	cd $(src) && \
		nim c --app:lib --out:fruzzy_mod.so $(infoopt)  fruzzy_mod

build:
	cd $(src) && \
		nim c --app:lib --out:fruzzy_mod.so $(relopt) fruzzy_mod

debug-single: build-debug
	@echo Testing native mod with minimal file
	cd $(src) && \
	python3 qc-single.py

debug-native: build-debug
	cd $(src) && \
	$(native) python3 qc-fast.py

debug:
	cd $(src) && \
	python3 qc-fast.py

test-py:
	cd $(src) && \
	pytest

test-native: build
	cd $(src) && \
	$(native) pytest


test: test-py test-native

win:
	cd $(src) && \
		nim c --app:lib $(win) --out:fruzzy_mod.pyd $(relopt) fruzzy_mod
all: test build
rel: win build
	ls -al $(src)/fruzzy_mod*
