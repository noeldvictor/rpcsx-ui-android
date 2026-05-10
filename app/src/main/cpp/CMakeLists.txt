cmake_minimum_required(VERSION 3.10)
project("rpcsx-ui-jni")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_POSITION_INDEPENDENT_CODE on)
option(RPCSX_BUILD_BUNDLED_CORE "Build the vendored RPCSX Android core into the APK" OFF)

if (CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
	add_subdirectory(libadrenotools)
else()
	add_library(adrenotools INTERFACE)
endif()

add_library(${CMAKE_PROJECT_NAME} SHARED native-lib.cpp)

target_link_libraries(${CMAKE_PROJECT_NAME}
    android
    log
    adrenotools
)

if (RPCSX_BUILD_BUNDLED_CORE)
	add_subdirectory(rpcsx/android rpcsx-bundled-core)
endif()
