# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(whisper_dart_library VERSION 0.0.1 LANGUAGES CXX)

set(WHISPER_LIBRARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/whisper.cpp")

if(ANDROID)
  set(GGML_OPENMP OFF)
endif()

set(GGML_CCACHE OFF)

if(UNIX)
  set(CMAKE_BUILD_RPATH "$ORIGIN")
endif()

if(UNIX)
set(CMAKE_INSTALL_RPATH "${CMAKE_BINARY_DIR}/lib")
endif()
# 设置生成动态库
SET(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries" FORCE)

# 设置输出目录
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib" CACHE PATH "Output directory for libraries" FORCE)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "Output directory for executables" FORCE)

# 设置禁止生成示例和测试程序
set(WHISPER_BUILD_TESTS OFF CACHE BOOL "Disable building tests" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "Disable building examples" FORCE)
#set(GGML_CUDA ON CACHE BOOL "Enable Cuda support" FORCE)
#set(GGML_VULKAN ON CACHE BOOL "Enable Cuda support" FORCE)
#set(GGML_BLAS ON CACHE BOOL "Enable Blas support" FORCE)
#set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -O2 -DNDEBUG")
set(GGML_STANDALONE ON CACHE BOOL "Enable GGML Standalone" FORCE)
set(CMAKE_BUILD_TYPE "Release")
# 添加子目录
add_subdirectory(${WHISPER_LIBRARY_DIR} "whisper.cpp")
if(ANDROID)
if (${ANDROID_ABI} STREQUAL "arm64-v8a")
    target_compile_options(whisper PRIVATE -march=armv8.2-a+fp16)
elseif (${ANDROID_ABI} STREQUAL "armeabi-v7a")
    target_compile_options(whisper PRIVATE -mfpu=neon-vfpv4)
endif ()
endif()
