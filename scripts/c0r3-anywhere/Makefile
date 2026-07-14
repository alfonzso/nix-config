SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.SILENT:

LIB := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/lib/c0r3-anywhere.sh)
PHASE ?= install

.DEFAULT_GOAL := help

.PHONY: help build-iso start-qemu nx-any-installer nx-any-installer-disko start-installed

help:
	bash "$(LIB)" help

build-iso:
	bash "$(LIB)" build-iso

start-qemu:
	bash "$(LIB)" start-qemu

nx-any-installer:
	bash "$(LIB)" nx-any-installer "$(PHASE)"

nx-any-installer-disko:
	$(MAKE) --no-print-directory nx-any-installer PHASE=disko

start-installed:
	bash "$(LIB)" start-installed
