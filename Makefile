SHELL := /usr/bin/env bash

.PHONY: help syntax test lint format-check check

help:
	@printf '%s\n' 'make syntax       Validate supported Bash syntax' \
	  'make test         Run the dependency-free test suite' \
	  'make lint         Run ShellCheck when installed' \
	  'make format-check Run shfmt when installed' \
	  'make check        Run every available check'

syntax:
	@find . -path './legacy' -prune -o -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n

test:
	@./tests/run.sh

lint:
	@command -v shellcheck >/dev/null || { printf '%s\n' 'shellcheck is not installed; skipping local lint'; exit 0; }
	@shellcheck -x install.sh bin/linux-software-installer lib/*.sh tests/*.sh
	@shellcheck modules/*/module.sh

format-check:
	@command -v shfmt >/dev/null || { printf '%s\n' 'shfmt is not installed; skipping local format check'; exit 0; }
	@shfmt -d -i 2 -ci -sr install.sh bin/linux-software-installer lib modules tests

check: syntax lint format-check test
