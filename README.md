<!--
    SPDX-FileCopyrightText: 2006-2023, Knut Reinert & Freie Universität Berlin
    SPDX-FileCopyrightText: 2016-2023, Knut Reinert & MPI für molekulare Genetik
    SPDX-License-Identifier: CC-BY-4.0
-->

# IVaction

Easy to use C++/CMake/ctest continuous integration github actions. Support for Linux, MacOS and Windows.

## Synopsis
```
      - uses: iv-project/IVaction@v9.9
        with:
          compiler: gcc12-cpp20-debug
```

## Platforms

For each OS it provides a custom action:

- iv-project/IVaction@v9.9

Each take following arguments:
- `compiler` (required) \
    Which compiler to use `gcc12-cpp20-release`, `clang16-cpp17-debug`, etc
    This string can be set togther from following options:
    - `gcc11` - selects gcc 11 (linux and macos)
    - `gcc12` - selects gcc 12 (linux and macos)
    - `gcc13` - selects gcc 13 (linux and macos)
    - `gcc14` - selects gcc 14 (linux and macos)
    - `clang15` - selects clang 15 (linux and macos)
    - `clang16` - selects clang 16 (linux and macos)
    - `clang17` - selects clang 17 (linux and macos)
    - `msvc` - selects msvc (windows)
    - `intel` - selects intels llvm compiler (linux)
    - `cpp17` - requests c++17
    - `cpp20` - requests c++20
    - `cpp23` - requests c++23
    - `release` - sets cmake build type to release
    - `debug` - sets cmake build type to debug
    - `strict` - activates stricter compiler flags (linux and macos)
    - `sanitize_address` - activates address sanitizer flags
    - `sanitize_undefined` - activates undefined behaviour sanitizer flags
    - `sanitize_thread` - activates thread sanitizer flags
    - `lcov` - generates and uploads code coverage data (linux)
    - `cpm_version_check` - checks if CPM and the dependencies are the newest version (linux)
    - `spdx_license_lint` - checks if all files follow spdx header licensing (linux)

- `cmake_flags` (optional, default: "") \
    additional cmake flags
- `threads`: (optional, default: 1) \
    number of threads to use
- `codecov_token`: (optional, default: "") \
    codecov secret, only required if code coverage is being required.
- `ctest_timeout` (optional, default: 7200) \
    ctest timeout value in seconds


## Example for linux
Activated on every pushes on PRs and update on the main branch.
Cancels running actions.

More complete example can be found in [fmindex_collection](https://github.com/SGSSGene/fmindex-collection/tree/main/.github/workflows).
```
name: "CI"

on:
  push:
    branches:
      - 'main'
  pull_request:

concurrency:
  group: ${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  build:
    name: ${{matrix.os}}-${{ matrix.compiler }}
    runs-on: ${{ matrix.os }}
    timeout-minutes: 30
    strategy:
      fail-fast: false
      matrix:
        include:
          - {os: ubuntu-22.04, compiler: spdx_reuse_lint}
          - {os: ubuntu-22.04, compiler: cpm_version_check}
          - {os: ubuntu-22.04, compiler: gcc13-cpp20-release}
          - {os: ubuntu-22.04, compiler: gcc12-cpp20-release}
          - {os: ubuntu-22.04, compiler: gcc11-cpp20-release}
          - {os: ubuntu-22.04, compiler: gcc13-cpp20-debug-sanitize_address}
          - {os: ubuntu-22.04, compiler: gcc13-cpp20-debug-sanitize_undefined}
          - {os: ubuntu-22.04, compiler: gcc13-cpp20-lcov}
          - {os: ubuntu-22.04, compiler: clang17-cpp20-release}
          - {os: macos-12, compiler: gcc13-cpp20-release}
          - {os: macos-12, compiler: clang17-cpp20-release}
    steps:
      - name: Standard IV-project testing
        uses: iv-project/IVaction@v9.5 # make sure this is the newest version
        with:
          compiler: ${{ matrix.compiler }}
          threads: 2
          codecov_token: ${{ secrets.CODECOV_TOKEN }}
```
