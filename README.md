<!--
    SPDX-FileCopyrightText: 2006-2023, Knut Reinert & Freie Universität Berlin
    SPDX-FileCopyrightText: 2016-2023, Knut Reinert & MPI für molekulare Genetik
    SPDX-License-Identifier: CC-BY-4.0
-->

# IVaction

Easy to use C++/CMake/ctest continuous integration github actions. Support for Linux, MacOS and Windows.

## Synopsis
```
      - uses: iv-project/IVaction@v10.10
        with:
          compiler: gcc15-cpp20-debug
```

## Platforms

For each OS it provides a custom action:

- iv-project/IVaction@v10.10

Each take following arguments:
- `compiler` (required) \
    Which compiler to use `gcc12-cpp20-release`, `clang16-cpp17-debug`, etc
    This string can be set together from following options:
    - `gcc11` - selects gcc 11 (linux and macos)
    - `gcc12` - selects gcc 12 (linux and macos)
    - `gcc13` - selects gcc 13 (linux and macos)
    - `gcc14` - selects gcc 14 (linux and macos)
    - `gcc15` - selects gcc 15 (linux and macos)
    - `gcc-latest`, `gcc-second-latest`, `gcc-third-latest` - referring to gcc15 , gcc14 and gcc13
    - `clang15` - selects clang 15 (linux and macos)
    - `clang16` - selects clang 16 (linux and macos)
    - `clang17` - selects clang 17 (linux and macos)
    - `clang18` - selects clang 18 (linux and macos)
    - `clang19` - selects clang 19 (linux and macos-13)
    - `clang20` - selects clang 20 (linux and macos)
    - `clang21` - selects clang 21 (linux and macos)
    - `clang-latest`, `clang-second-latest`, `clang-third-latest` - referring to clang21 , clang20 and clang19
    - `msvc` - selects msvc (windows)
    - `intel` - selects intels llvm compiler (linux)
    - `emscripten` - selects 32bit emscripten as compiler (linux)
    - `emscripten64` - selects 64bit emscripten as compiler (linux)
    - `cpp17` - requests c++17
    - `cpp20` - requests c++20
    - `cpp23` - requests c++23
    - `cpp26` - requests c++26
    - `release` - sets cmake build type to release
    - `debug` - sets cmake build type to debug
    - `relwithdebinfo` - sets cmake build type to relwithdebinfo
    - `strict` - activates stricter compiler flags
    - `sanitize_address` - activates address sanitizer flags (linux and windows)
    - `sanitize_undefined` - activates undefined behaviour sanitizer flags (linux)
    - `sanitize_thread` - activates thread sanitizer flags (linux)
    - `lcov` - generates and uploads code coverage data (linux)
    - `cpm_version_check` - checks if CPM and the dependencies are the newest version (linux)
    - `cpm_version_check_inline` - check if CPM and the dependencies are the newest version by calling CPM_CHECK_VERSION target (linux)
    - `cpm_update_version` - check cpm dependency file and creates an PR with fix (linux)
    - `spdx_license_lint` - checks if all files follow spdx header licensing (linux)
    - `check_tag` - checks if the current HEAD has a tag (linux)
    - `pytest` - runs additional pytest on <REPO_PATH>/tests
    - `notests` - will not run any ctests
    - `open_issue` - will open an issue on failure

- `cmake_flags` (optional, default: "") \
    additional cmake flags
- `cmake_c_flags` (optional, default: "") \
    additional `CMAKE_C_FLAGS`
- `cmake_cxx_flags` (optional, default: "") \
    additional `CMAKE_CXX_FLAGS`
- `threads`: (optional, default: 1) \
    number of threads to use
- `codecov_token`: (optional, default: "") \
    codecov secret, only required if code coverage is being required.
- `ctest_timeout` (optional, default: 7200) \
    ctest timeout value in seconds
- `age_of_last_commit` (optional, default: 7) \
    warn if HEAD is old and has no tag (in days). Only valid for check_tag.
- `cpm_dependency_file` (optional, default: "cpm.dependencies")
    the dependency file that should be checked and updated
-  `github_token`:
    pass through of the GITHUB token, needed by open_issue and cpm_dependency_file

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
          - {os: ubuntu-22.04, compiler: spdx_license_lint}
          - {os: ubuntu-22.04, compiler: cpm_version_check}
          - {os: ubuntu-22.04, compiler: gcc15-cpp20-release}
          - {os: ubuntu-22.04, compiler: gcc14-cpp20-release}
          - {os: ubuntu-22.04, compiler: gcc13-cpp20-release}
          - {os: ubuntu-22.04, compiler: gcc15-cpp20-debug-sanitize_address}
          - {os: ubuntu-22.04, compiler: gcc15-cpp20-debug-sanitize_undefined}
          - {os: ubuntu-22.04, compiler: gcc15-cpp20-lcov}
          - {os: ubuntu-22.04, compiler: clang20-cpp20-release}
          - {os: macos-14,     compiler: gcc15-cpp20-release}
          - {os: macos-14,     compiler: clang20-cpp20-release}
    steps:
      - name: Standard IV-project testing
        uses: iv-project/IVaction@v10.10 # make sure this is the newest version
        with:
          compiler: ${{ matrix.compiler }}
          threads: 2
          codecov_token: ${{ secrets.CODECOV_TOKEN }}
```
