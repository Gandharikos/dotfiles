cmake_minimum_required(VERSION 3.25)

project(
  qt_quick_app
  VERSION 0.1.0
  DESCRIPTION "A C++23 and Qt Quick application"
  LANGUAGES CXX)

include(CTest)
include(GNUInstallDirs)

option(QT_QUICK_APP_ENABLE_CLANG_TIDY "Run clang-tidy while compiling" OFF)

set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Qml Quick QuickControls2 Test)
qt_standard_project_setup(REQUIRES 6.8)

if(QT_QUICK_APP_ENABLE_CLANG_TIDY)
  find_program(CLANG_TIDY_EXECUTABLE NAMES clang-tidy REQUIRED)
  set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXECUTABLE}")
endif()

set_source_files_properties(qml/Main.qml PROPERTIES QT_RESOURCE_ALIAS Main.qml)
set_source_files_properties(
  qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE QT_RESOURCE_ALIAS
                                                      Theme.qml)

qt_add_executable(qt-quick-app src/main.cpp)

qt_add_qml_module(
  qt-quick-app
  URI
  QtQuickTemplate
  VERSION
  1.0
  SOURCES
  include/qt_quick_app/app_model.hpp
  src/app_model.cpp
  QML_FILES
  qml/Main.qml
  qml/Theme.qml)

target_include_directories(qt-quick-app PRIVATE include include/qt_quick_app)
target_link_libraries(qt-quick-app PRIVATE Qt6::Qml Qt6::Quick
                                           Qt6::QuickControls2)
target_compile_features(qt-quick-app PRIVATE cxx_std_23)
target_compile_definitions(qt-quick-app
                           PRIVATE QT_QUICK_APP_VERSION="${PROJECT_VERSION}")

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
  target_compile_options(qt-quick-app PRIVATE -Wall -Wextra -Wpedantic
                                              -Wconversion -Wsign-conversion)
endif()

set_target_properties(
  qt-quick-app
  PROPERTIES MACOSX_BUNDLE TRUE
             MACOSX_BUNDLE_BUNDLE_NAME "Qt Quick App"
             MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
             MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
             WIN32_EXECUTABLE TRUE)

install(
  TARGETS qt-quick-app
  BUNDLE DESTINATION .
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

if(BUILD_TESTING)
  qt_add_executable(qt-quick-app-tests tests/app_model_test.cpp
                    src/app_model.cpp include/qt_quick_app/app_model.hpp)
  target_include_directories(qt-quick-app-tests PRIVATE include)
  target_link_libraries(qt-quick-app-tests PRIVATE Qt6::Qml Qt6::Test)
  target_compile_features(qt-quick-app-tests PRIVATE cxx_std_23)

  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    target_compile_options(
      qt-quick-app-tests PRIVATE -Wall -Wextra -Wpedantic -Wconversion
                                 -Wsign-conversion)
  endif()

  add_test(NAME app-model COMMAND qt-quick-app-tests)
endif()
