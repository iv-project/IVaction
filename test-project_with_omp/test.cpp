// SPDX-FileCopyrightText: 2025 Simon Gene Gottlieb
// SPDX-License-Identifier: CC0-1.0

#include <iostream>

#ifdef TESTPROJECT_OPENMP
#include <omp.h>
size_t f() {
    return omp_get_thread_num();
}
#else
size_t f() { return 0; }
#endif

int main() {
    std::cout << "Hello World! " << f() << "\n";
}
