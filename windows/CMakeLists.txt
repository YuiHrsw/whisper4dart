# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "whisper4dart")
project(${PROJECT_NAME} LANGUAGES CXX)

# 读取文件内容
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/../config.txt" CONFIG_CONTENT)

# 使用正则表达式匹配键值对
string(REGEX MATCH "USE_PREBUILT_LIBS=([A-Za-z0-9_]*)" USE_PREBUILT_LIBS_MATCH "${CONFIG_CONTENT}")

# 提取值并设置为全局变量
if(USE_PREBUILT_LIBS_MATCH)
    string(REPLACE "USE_PREBUILT_LIBS=" "" USE_PREBUILT_LIBS_VALUE "${USE_PREBUILT_LIBS_MATCH}")
    set(USE_PREBUILT_LIBS ${USE_PREBUILT_LIBS_VALUE} CACHE INTERNAL "Global variable from file")
endif()

# 输出变量值以验证
message(STATUS "USE_PREBUILT_LIBS: ${USE_PREBUILT_LIBS}")

if(USE_PREBUILT_LIBS)
  message(STATUS "USE_PREBUILT_LIBS is true")

  




  file(GLOB WHISPER_BUILD_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../prebuilt/windows/*")

else()
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


endif()


set(whisper4dart_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  "${WHISPER_BUILD_PATH}"
  PARENT_SCOPE
)
