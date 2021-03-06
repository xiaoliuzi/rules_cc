#!/bin/bash

# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

function check_symbol_present() {
  message="Should have seen '$2' but didn't."
  echo "$1" | (grep -q "$2" || (echo "$message" && exit 1))
}

function check_symbol_absent() {
  message="Shouldn't have seen '$2' but did."
  if [ "$(echo $1 | grep -c $2)" -gt 0 ]; then
    echo "$message"
    exit 1
  fi
}

function test_shared_library_symbols() {
  foo_so=$(find . -name libfoo_so.so)
  symbols=$(nm -D $foo_so)
  check_symbol_present "$symbols" "U _Z3barv"
  check_symbol_present "$symbols" "T _Z3bazv"
  check_symbol_present "$symbols" "T _Z3foov"
  # Check that the preloaded dep symbol is not present
  check_symbol_present "$symbols" "U _Z13preloaded_depv"

  check_symbol_absent "$symbols" "_Z3quxv"
  check_symbol_absent "$symbols" "_Z4bar3v"
  check_symbol_absent "$symbols" "_Z4bar4v"
}

function test_binary() {
  binary=$(find . -name binary)
  symbols=$(nm -D $binary)
  check_symbol_present "$symbols" "T _Z13preloaded_depv"
  check_symbol_present "$symbols" "U _Z3foov"
  $binary | (grep -q "hello 42" || (echo "Expected 'hello 42'" && exit 1))
}

test_shared_library_symbols
test_binary
