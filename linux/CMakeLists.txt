# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

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

  file(GLOB WHISPER_BUILD_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../prebuilt/linux/*")

  set(whisper4dart_bundled_libraries
    # Defined in ../src/CMakeLists.txt.
    # This can be changed to accommodate different builds.
    "${WHISPER_BUILD_PATH}"
    PARENT_SCOPE
  )



else()
  # Invoke the build for native code shared with the other target platforms.
  # This can be changed to accommodate different builds.
  add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/shared")

  # List of absolute paths to libraries that should be bundled with the plugin.
  # This list could contain prebuilt libraries, or libraries created by an
  # external build triggered from this build file.
  set(whisper4dart_bundled_libraries
    # Defined in ../src/CMakeLists.txt.
    # This can be changed to accommodate different builds.
    $<TARGET_FILE:whisper>
    PARENT_SCOPE
  )


endif()