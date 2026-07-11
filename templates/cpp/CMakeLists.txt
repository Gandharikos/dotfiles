cmake_minimum_required(VERSION 3.25)

project(
  sample-cpp
  VERSION 0.1.0
  LANGUAGES CXX
)

add_executable(sample-cpp src/main.cpp)

target_compile_features(sample-cpp PRIVATE cxx_std_23)
target_compile_options(sample-cpp PRIVATE -Wall -Wextra -Wpedantic)

install(TARGETS sample-cpp RUNTIME DESTINATION bin)
