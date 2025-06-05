# SPDX-FileCopyrightText: 2025 Simon Gene Gottlieb
# SPDX-License-Identifier: CC0-1.0

cmake_minimum_required (VERSION 3.25)

project(test-project LANGUAGES CXX DESCRIPTION "test project")
add_executable(test-project
    test.cpp
    test2.cpp
)
enable_testing()
add_test(NAME test-project COMMAND test-project)
