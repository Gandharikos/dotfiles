cmake_minimum_required(VERSION 3.24)

project(
  qt_app
  VERSION 0.1.0
  DESCRIPTION "A minimal C++20 and Qt 6 Widgets application"
  LANGUAGES CXX)

include(GNUInstallDirs)

option(QT_APP_ENABLE_CLANG_TIDY "Run clang-tidy while compiling" OFF)

set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Widgets)
qt_standard_project_setup()

if(QT_APP_ENABLE_CLANG_TIDY)
  find_program(CLANG_TIDY_EXECUTABLE NAMES clang-tidy REQUIRED)
  set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXECUTABLE}")
endif()

qt_add_executable(qt-app src/main.cpp src/main_window.cpp
                  include/qt_app/main_window.hpp)
target_include_directories(qt-app PRIVATE include)
target_link_libraries(qt-app PRIVATE Qt6::Widgets)
target_compile_features(qt-app PRIVATE cxx_std_20)
target_compile_definitions(qt-app PRIVATE QT_APP_VERSION="${PROJECT_VERSION}")

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
  target_compile_options(qt-app PRIVATE -Wall -Wextra -Wpedantic -Wconversion
                                        -Wsign-conversion)
endif()

set_target_properties(
  qt-app
  PROPERTIES MACOSX_BUNDLE TRUE
             MACOSX_BUNDLE_BUNDLE_NAME "Qt App"
             MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
             MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
             WIN32_EXECUTABLE TRUE)

install(
  TARGETS qt-app
  BUNDLE DESTINATION .
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
