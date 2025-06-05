// SPDX-FileCopyrightText: 2025 Simon Gene Gottlieb
// SPDX-License-Identifier: CC0-1.0

#if __cplusplus > 202002L
#include <iostream>
#include <print>

int f();

int main() {
  std::println("{}", "Olá");
  std::cout << "Hello World! " << f() << "\n";
  return 0;
}
#else
#include <iostream>

int f();

int main() {
  std::cout << "Hello World! " << f() << "\n";
  return 0;
}
#endif
