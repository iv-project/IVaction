#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2025 Simon Gene Gottlieb
# SPDX-License-Identifier: CC0-1.0

set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

COMPILER="$1"
shift
CMAKE_FLAGS="${CMAKE_FLAGS:-}"
CMAKE_C_FLAGS="${CMAKE_C_FLAGS:-}"
CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS:-}"
THREADS="${THREADS:-1}"
CODECOV_TOKEN="${CODECOV_TOKEN:-}"
RUNNER_OS="${RUNNER_OS:-$(uname -a | cut -d ' ' -f 1)}"
MATRIX_OS="${MATRIX_OS:-${RUNNER_OS}}"
AGE_OF_LAST_COMMIT="${AGE_OF_LAST_COMMIT:-7}"  # warn if HEAD is old and has no tag (in days)
ACTION_PATH="${ACTION_PATH:-${SCRIPT_DIR}}"
GITHUB_REF_NAME="${GITHUB_REF_NAME:-$(git branch --show-current)}"
CTEST_TIMEOUT="${CTEST_TIMEOUT:-7200}"         # ctest timeout value in seconds
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
CPM_DEPENDENCY_FILE="${CPM_DEPENDENCY_FILE:-}" # the dependency file that should be checked and updated
SDKROOT=
CMAKE_LAUNCHER=

bash --version

check_cmd() {
    cmd="$1"
    A=($(echo $COMPILER | tr '-' ' '))
    for a in "${A[@]}"; do
        if [ "${a}" == "${cmd}" ]; then
            return 0
        fi
    done
#    if [[ ${A[@]} =~ $(echo "\<$cmd\>") ]]; then
#        return 0
#    fi
    return 1
}

compile_cmds=("gcc11" "gcc12" "gcc13" "gcc14"
              "clang15" "clang16" "clang17" "clang18" "clang19"
              "intel"
              "emscripten"
              "msvc"
)

check_has_compile_cmd() {
    for e in $(echo $COMPILER | tr '-' ' '); do
        for a in "${compile_cmds[@]}"; do
            if [ "${a}" == "${e}" ]; then
                return 0
            fi
        done
    done
    return 1
}

valid_cmds=("nosetup"
            "check_tag"
            "spdx_license_lint"
            "cpp11" "cpp14" "cpp17" "cpp20" "cpp23"
            "release" "debug" "relwithdebinfo"
            "strict"
            "sanitize_address" "sanitize_undefined" "sanitize_thread"
            "lcov"
            "cpm_version_check" "cpm_version_check_inline" "cpm_update_version"
            "notests"
            "open_issue"
)
valid_cmds+=(${compile_cmds[@]})

for e in $(echo $COMPILER | tr '-' ' '); do
    SUCCESS=0
    for a in "${valid_cmds[@]}"; do
        if [ "${a}" == "${e}" ]; then
            SUCCESS=1
        fi
    done
    if [ "$SUCCESS" == "0" ]; then
        echo "command \"$e\" unknown"
        exit 1
    fi
done

echo "## Initialize environment"
echo "Setup for ${COMPILER}"
export CXX_STANDARD=20
export BUILD_TYPE=Release
export CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS}"
export CMAKE_C_FLAGS="${CMAKE_C_FLAGS}"
export CMAKE_ARGS=
export GCOV=gcov
export REPO_PATH=${REPO_PATH:-$(pwd)}
export REPO_PATH=$(realpath ${REPO_PATH})
rm -f message.txt

echo CMAKE_FLAGS=$CMAKE_FLAGS
echo CMAKE_C_FLAGS=$CMAKE_C_FLAGS
echo CMAKE_CXX_FLAGS=$CMAKE_CXX_FLAGS
echo THREADS=$THREADS
echo CODECOV_TOKEN=$CODECOV_TOKEN
echo RUNNER_OS=$RUNNER_OS
echo MATRIX_OS=$MATRIX_OS
echo AGE_OF_LAST_COMMIT=$AGE_OF_LAST_COMMIT
echo ACTION_PATH=$ACTION_PATH
echo GITHUB_REF_NAME=$GITHUB_REF_NAME
echo CTEST_TIMEOUT=$CTEST_TIMEOUT
echo GITHUB_TOKEN=$GITHUB_TOKEN
echo CPM_DEPENDENCY_FILE=$CPM_DEPENDENCY_FILE
echo REPO_PATH=$REPO_PATH
check_has_compile_cmd && echo "must compile"
check_has_compile_cmd || echo "no compile"

if [ "$RUNNER_OS" = "Linux" ] && check_cmd "check_tag"; then
  echo "## Check if tagged"
  cd ${REPO_PATH}
  current_time=$(date +%s)
  echo "current time: ${current_time}"
  last_commit=$(git log -1 --format=%at HEAD)
  echo "last commit: ${last_commit}"
  diff=$(expr ${current_time} - ${last_commit})
  time_passed=$(echo ${diff} / 86400 | bc)

  echo "time_passed: ${time_passed}"
  if [ ${time_passed} -ge ${AGE_OF_LAST_COMMIT} ]; then
    git describe --tags --exact-match HEAD
    if [ $? -ne 0 ]; then
      echo "git tag out of date" > message.txt
      exit 1
    fi
  fi
fi
if [ "$RUNNER_OS" = "Linux" ] && ! check_cmd "nosetup"; then
  echo "## Install tools (Linux)"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  sudo apt-get update -y
  sudo apt-get install -y build-essential
  brew upgrade
elif [ "$RUNNER_OS" = "macOS" ] && ! check_cmd "nosetup"; then
  echo "## Install tools (macOS)"
  eval "$(brew shellenv)"
  brew update-reset
  brew install --force-bottle --overwrite cmake pkg-config
fi

setup_gcc_v() {
    v=$1
    if ! check_cmd "nosetup"; then
      echo "## Setup gcc ${v} (Linux, macOS)"
      brew install --force-bottle gcc@${v}
      brew link -f gcc@${v}
      export CXX=g++-${v}
      export CC=gcc-${v}
      export GCOV=gcov-${v}

      #Only needed for macos
      export SDKROOT=$(gcc-${v} -v 2>&1 | sed -n 's@.*--with-sysroot=\([^ ]*\).*@\1@p')
    fi
}

setup_clang_v() {
    v=$1
    if ! check_cmd "nosetup"; then
        echo "## Setup clang ${v} (Linux, macOS)"
        brew install --force-bottle llvm@${v}
        brew link -f llvm@${v}
        export CXX=clang++
        export CC=clang
        INSTALL_PREFIX=$(brew --prefix llvm@${v})
        export PATH="${INSTALL_PREFIX}/bin:$PATH"
        export LDFLAGS="-L${INSTALL_PREFIX}/lib/c++ -Wl,-rpath,${INSTALL_PREFIX}/lib/c++"
    fi
}

if [ "$RUNNER_OS" = "Linux" ] || [ "$RUNNER_OS" = "macOS" ]; then
  if check_cmd "gcc11"; then       setup_gcc_v 11
  elif check_cmd "gcc12"; then     setup_gcc_v 12
  elif check_cmd "gcc13"; then     setup_gcc_v 13
  elif check_cmd "gcc14"; then     setup_gcc_v 14
  elif check_cmd "clang15"; then   setup_clang_v 15
  elif check_cmd "clang16"; then   setup_clang_v 16
  elif check_cmd "clang17"; then   setup_clang_v 17
  elif check_cmd "clang18"; then   setup_clang_v 18
  elif check_cmd "clang19"; then
    setup_clang_v 19
    if [ "$RUNNER_OS" = "macOS" ]; then
      echo "## Setup clang 19 (macOS) - Part 2"
      if [ "${MATRIX_OS}" == "macos-14" ]; then
        export LDFLAGS="${LDFLAGS} -L/opt/homebrew/opt/llvm/lib/unwind -lunwind"
      fi
      export CMAKE_ARGS="-DLIBCXXABI_USE_LLVM_UNWINDER=OFF -DCOMPILER_RT_USE_LLVM_UNWINDER=OFF"
    fi
  fi
fi
if [ "$RUNNER_OS" = "Linux" ] && check_cmd "intel"; then
  echo "## Setup intel (Linux)"
  if ! check_cmd "nosetup"; then
      wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
      sudo apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
      rm GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
      sudo echo "deb https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list
      sudo apt-get update -y
      sudo apt-get install -y intel-oneapi-compiler-dpcpp-cpp
      set +eu
      source /opt/intel/oneapi/setvars.sh
      set -eu
      sudo ln -fs $(icpx --print-prog-name=llvm-ar) /usr/bin/ar
      sudo ln -fs $(icpx --print-prog-name=lld) /usr/bin/ld
      sudo ln -fs $(icpx --print-prog-name=llvm-nm) /usr/bin/nm
      sudo ln -fs $(icpx --print-prog-name=llvm-ranlib) /usr/bin/ranlib
  else
      set +eu
      source /opt/intel/oneapi/setvars.sh
      set -eu
  fi
  export CC=icx
  export CXX=icpx
elif [ "$RUNNER_OS" = "Linux" ] && check_cmd "emscripten" && ! check_cmd "nosetup"; then
  echo "## Setup emscripten"
  git clone https://github.com/emscripten-core/emsdk.git
  (
    cd emsdk
    git pull
    ./emsdk install latest
    ./emsdk activate latest
  )
  source emsdk/emsdk_env.sh
  export CMAKE_LAUNCHER=emcmake
fi

for v in 11 14 17 20 23; do
    if check_cmd "cpp${v}"; then
      echo "## Setup c++${v}"
      export CXX_STANDARD=${v}
    fi
done

if check_cmd "release"; then
  echo "## Setup Release"
  export BUILD_TYPE=Release
elif check_cmd "debug"; then
  echo "## Setup Debug"
  export BUILD_TYPE=Debug
  if [ "${RUNNER_OS}" != "Windows" ]; then
    export CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -fno-omit-frame-pointer"
    export CMAKE_C_FLAGS="${CMAKE_C_FLAGS} -fno-omit-frame-pointer"
  fi
elif check_cmd "relwithdebinfo"; then
  echo "## Setup RelWithDebInfo"
  export BUILD_TYPE=RelWithDebInfo
  if [ "${RUNNER_OS}" != "Windows" ]; then
    export CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -fno-omit-frame-pointer"
    export CMAKE_C_FLAGS="${CMAKE_C_FLAGS} -fno-omit-frame-pointer"
  fi
fi

if check_cmd "strict"; then
  echo "## Setup Strict"
  if [ "${RUNNER_OS}" == "Windows" ]; then
    export CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} /Wall /WX"
    export CMAKE_C_FLAGS="${CMAKE_C_FLAGS} /Wall /WX"
  else
    export CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -Wall -Werror -Wpedantic -Wextra"
    export CMAKE_C_FLAGS="${CMAKE_C_FLAGS} -Wall -Werror -Wpedantic -Wextra"
  fi
fi

for e in "address" "undefined" "thread"; do
  if [ "$RUNNER_OS" = "Linux" ] && check_cmd "sanitize_${e}"; then
    echo "## Setup Sanitize ${e} (Linux)"
    export CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -fsanitize=${e}"
    export CMAKE_C_FLAGS="${CMAKE_C_FLAGS} -fsanitize=${e}"
  fi
done

if [ "$RUNNER_OS" = "Windows" ] && check_cmd "sanitize_thread"; then
  echo "## Setup Sanitize Thread (Windows)"
  export CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} /fsanitize=address"
  export CMAKE_C_FLAGS="${CMAKE_C_FLAGS} /fsanitize=address"
fi

if [ "$RUNNER_OS" = "Linux" ]; then
  if check_cmd "lcov" && ! check_cmd "nosetup"; then
    echo "## Setup lcov (Linux)"
    sudo apt-get install lcov
    lcov --version
  fi
  if check_cmd "lcov"; then
    export BUILD_TYPE=Debug
    export CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} --coverage"
    export CMAKE_C_FLAGS="${CMAKE_C_FLAGS} --coverage"
  fi

  if check_cmd "cpm_version_check"; then
    echo "## cpm_version_check (Linux)"
    cp -r "${ACTION_PATH}"/cpm_check_version .
    cd cpm_check_version
    cmake .
    make CPM_CHECK_NEWER_PACKAGES
  fi

  if check_cmd "cpm_version_check_inline"; then
    echo "## cpm_version_check_inline (Linux)"
    mkdir -p ${REPO_PATH}/build && cd $_
    cmake .. -DCPM_CHECK_VERSION_ENABLED=TRUE ${CMAKE_FLAGS}
    make CPM_CHECK_NEWER_PACKAGES
  fi

  if check_cmd "cpm_version_check" && ! check_cmd "nosetup"; then
    echo "## cpm_update_version (Linux)"
    export GH_TOKEN=${GITHUB_TOKEN}
    brew install --force-bottle jq
    brew link -f jq
    git config --global user.email "ivaction@noemail.com"
    git config --global user.name "IVaction"
  fi
  if check_cmd "cpm_version_check"; then
    cd $REPO_PATH
    ${ACTION_PATH}/fix_dependency_file/updatePackagesAndPR.sh ${CPM_DEPENDENCY_FILE} $'\nclose and reopen this issue to trigger CI\n(generated by IVAction)'
  fi
fi

if ([ "$RUNNER_OS" = "Linux" ] || [ "$RUNNER_OS" = "macOS" ]) && check_has_compile_cmd; then
  echo "## Tool versions (Linux, macOS)"
  cmake --version
  echo "SDKROOT: ${SDKROOT}"
  ${CXX:-echo} --version

  echo "## Configure tests (Linux, macOS)"
  mkdir -p ${REPO_PATH}/build && cd $_
  pwd
  echo "${CMAKE_LAUNCHER} cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_CXX_STANDARD=${CXX_STANDARD} ${CMAKE_FLAGS} -DCMAKE_CXX_FLAGS=\"${CMAKE_CXX_FLAGS}\" -DCMAKE_C_FLAGS=\"${CMAKE_C_FLAGS}\" ${CMAKE_ARGS}"
  ${CMAKE_LAUNCHER} cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_CXX_STANDARD=${CXX_STANDARD} ${CMAKE_FLAGS} -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS}" -DCMAKE_C_FLAGS="${CMAKE_C_FLAGS}" ${CMAKE_ARGS}

  echo "## Build tests (Linux, macOS)"
  make -k -j ${THREADS} VERBOSE=1
fi

if [ "$RUNNER_OS" = "Linux" ] && check_cmd "lcov"; then
  echo "## Generate base coverage"

  cd ${REPO_PATH}/build
  echo ${GCOV}
  lcov -c -i --directory . --output coverage_base.info --gcov ${GCOV} --base-directory .. || true
fi

if ([ "$RUNNER_OS" = "Linux" ] || [ "$RUNNER_OS" = "macOS" ]) && check_has_compile_cmd && ! check_cmd "notests"; then
  echo "## Run tests (Linux, macOS)"
  cd ${REPO_PATH}/build
  ctest --verbose . -j ${THREADS} --output-on-failure --timeout ${CTEST_TIMEOUT} || ctest --verbose . -j ${THREADS} --output-on-failure --timeout ${CTEST_TIMEOUT} --rerun-failed
fi

if [ "$RUNNER_OS" = "Linux" ] && check_cmd "lcov"; then
  echo "## Generate Coverage report and upload (Linux)"
  cd ${REPO_PATH}/build
  lcov -c --directory . --output coverage_test.info --gcov ${GCOV} --base-directory ..
  lcov -a coverage_base.info -a coverage_test.info -o coverage.info
  lcov --extract coverage.info '*/repo/*' --output-file coverage.info || true
  lcov --remove coverage.info --ignore-errors unused '*/repo/lib/*' --output-file coverage.info || true
  lcov --remove coverage.info --ignore-errors unused '*/repo/docs/*' --output-file coverage.info || true
  lcov --remove coverage.info --ignore-errors unused '*/repo/CMakeCCompilerId.c' --output-file coverage.info || true
  lcov --remove coverage.info --ignore-errors unused '*/repo/CMakeCXXCompilerId.cpp' --output-file coverage.info || true
  lcov --list coverage.info
  curl -Os https://uploader.codecov.io/latest/linux/codecov
  chmod +x codecov
  if [ -n "${CODECOV_TOKEN}" ]; then
    export CODECOV="-t ${CODECOV_TOKEN}"
  fi
  ./codecov ${CODECOV:-} -f coverage.info -B $GITHUB_REF_NAME
fi

if [ "$RUNNER_OS" = "Windows" ]; then
  echo "## Build something requiring CL.EXE (Windows)"
  mkdir -p ${REPO_PATH}/build && cd $_
  echo cmake .. -G "NMake Makefiles" -DCMAKE_TOOLCHAIN_FILE="C:/vcpkg/scripts/buildsystems/vcpkg.cmake" -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_CXX_STANDARD=${CXX_STANDARD} ${CMAKE_FLAGS} -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS}" -DCMAKE_C_FLAGS="${CMAKE_C_FLAGS}"
  cmake .. -G "NMake Makefiles" -DCMAKE_TOOLCHAIN_FILE="C:/vcpkg/scripts/buildsystems/vcpkg.cmake" -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_CXX_STANDARD=${CXX_STANDARD} ${CMAKE_FLAGS} -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS}" -DCMAKE_C_FLAGS="${CMAKE_C_FLAGS}"
  echo nmake VERBOSE=1
  nmake VERBOSE=1
fi

if [ "$RUNNER_OS" = "Windows" ] && ! check_cmd "notests"; then
  echo "## Run tests (Windows)"
  cd ${REPO_PATH}/build
  ctest --verbose . -j ${THREADS} --output-on-failure --timeout ${CTEST_TIMEOUT}
fi
