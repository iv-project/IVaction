# SPDX-FileCopyrightText: 2025 Simon Gene Gottlieb
# SPDX-License-Identifier: CC0-1.0

cmake_minimum_required (VERSION 3.25)

project(test-project LANGUAGES CXX DESCRIPTION "test project")
add_library(test-lib
    test2.cpp
    test3.cpp
)

add_executable(test-project
    test.cpp
)
target_link_libraries(test-project PRIVATE
    test-lib
)
enable_testing()
add_test(NAME test-project COMMAND test-project)
