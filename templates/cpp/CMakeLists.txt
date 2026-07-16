cmake_minimum_required(VERSION 3.24)

project(
  cpp_app
  VERSION 0.1.0
  DESCRIPTION "A minimal C++20 application"
  LANGUAGES CXX)

include(GNUInstallDirs)

option(CPP_APP_ENABLE_CLANG_TIDY "Run clang-tidy while compiling" OFF)

set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(CPP_APP_ENABLE_CLANG_TIDY)
  find_program(CLANG_TIDY_EXECUTABLE NAMES clang-tidy REQUIRED)
  set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXECUTABLE}")
endif()

add_executable(cpp-app src/main.cpp)
target_compile_features(cpp-app PRIVATE cxx_std_20)
target_compile_definitions(cpp-app PRIVATE CPP_APP_VERSION="${PROJECT_VERSION}")

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
  target_compile_options(cpp-app PRIVATE -Wall -Wextra -Wpedantic -Wconversion
                                         -Wsign-conversion)
endif()

install(TARGETS cpp-app RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
