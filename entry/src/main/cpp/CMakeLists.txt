cmake_minimum_required(VERSION 3.5.0)
project(SCTerminalRunner)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

add_library(runner SHARED runner.cpp)

target_include_directories(runner PUBLIC
  ${NATIVERENDER_ROOT_PATH}
  ${NATIVERENDER_ROOT_PATH}/include
)

target_link_libraries(runner PUBLIC libace_napi.z.so libhilog_ndk.z.so)
