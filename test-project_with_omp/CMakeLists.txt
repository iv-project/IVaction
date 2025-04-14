# SPDX-FileCopyrightText: 2025 Simon Gene Gottlieb
# SPDX-License-Identifier: CC0-1.0

cmake_minimum_required (VERSION 3.25)

project(test-project_with_omp LANGUAGES C CXX DESCRIPTION "test project")
find_package(OpenMP QUIET)

add_executable(test-project_with_omp
    test.cpp
)

if (OpenMP_C_FOUND)
    target_compile_definitions(test-project_with_omp PUBLIC TESTPROJECT_OPENMP)
    target_link_libraries(test-project_with_omp PRIVATE OpenMP::OpenMP_C)
endif()
enable_testing()
add_test(NAME test-project_with_omp COMMAND test-project_with_omp)
