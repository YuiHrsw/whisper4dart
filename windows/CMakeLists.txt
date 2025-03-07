# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "whisper_dart")
project(${PROJECT_NAME} LANGUAGES CXX)
include(ExternalProject)
#terrible hack.
#I do this only because add_subdirectory is not supported in flutter plugin.
#see https://github.com/flutter/flutter/issues/95530 for more details.
ExternalProject_Add(
    whisper_build_windows
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src
    BINARY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src/whisper_build/windows
    
    BUILD_COMMAND cmake --build ${CMAKE_CURRENT_SOURCE_DIR}/../src/whisper_build/windows --config Release
    INSTALL_COMMAND ""
)


file(GLOB WHISPER_BUILD_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../src/whisper_build/windows/bin/Release/*")
set(whisper_dart_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  "${WHISPER_BUILD_PATH}"
  PARENT_SCOPE
)
