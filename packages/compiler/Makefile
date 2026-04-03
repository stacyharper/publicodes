help : Makefile
	@sed -n 's/^#> //p' $<

JS_TESTS_DIR = tests/runtimes/JS
JS_BENCHMARKS_DIR = benchmarks/JS
CLI_DIR = ../cli
COMPILER_PATH = _build/default/bin/main.exe

#> install                  | Install OCaml dependencies using opam
install:
	@echo "Installing dependencies..."
	opam install . --deps-only --with-test --with-doc --with-dev-setup

#> install-js               | Install JavaScript dependencies using yarn
install-js:
	@echo "Installing JavaScript dependencies..."
	yarn --cwd $(JS_TESTS_DIR) install
	yarn --cwd $(JS_BENCHMARKS_DIR) install

#> build                    | Build the compiler using dune
build:
	@echo "Building the project..."
	dune build

#> dev                      | Run the dune build in watch mode for development (needed for LSP server)
dev:
	dune build --watch

#> test-all						      | Run all tests (JavaScript and OCaml)
test-all: test-ocaml test-js

#> test-js                  | Run JavaScript tests using yarn
test-js: build
	@echo "Running JavaScript tests..."
	PUBLICODES_COMPILER_PATH=../../../$(COMPILER_PATH) yarn --cwd $(JS_TESTS_DIR) test

#> test-ocaml               | Run OCaml unit and cram tests using dune
test-ocaml:
	@echo "Running OCaml tests..."
	dune test

#> test-ocaml-promote       | Run OCaml tests and promote cram test outputs
test-ocaml-promote:
	@echo "Running OCaml tests and promoting cram test outputs..."
	dune promote

#> bench-tjm                | Run the 'simple-TJM' example benchmark
bench-tjm:
	@echo "Running 'simple-TJM' benchmark..."
	# yarn --cwd $(JS_BENCHMARKS_DIR) compile:simple-TJM
	yarn --cwd $(JS_BENCHMARKS_DIR) benchmark:simple-TJM

#> bench-auto-entrepeneur  | Run the 'auto-entrepreneur' example benchmark
bench-auto-entrepeneur:
	@echo "Running 'auto-entrepreneur' benchmark..."
	yarn --cwd $(JS_BENCHMARKS_DIR) compile:auto-entrepreneur
	yarn --cwd $(JS_BENCHMARKS_DIR) benchmark:auto-entrepreneur
