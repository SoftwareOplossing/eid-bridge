# SPDX-FileCopyrightText: Let's Peppol contributors
# SPDX-License-Identifier: MIT
cmake_minimum_required(VERSION 3.22)
project(beid-probe LANGUAGES CXX)
if(NOT WIN32 OR NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "The initial probe requires 64-bit Windows")
endif()

set(eid_library "${CMAKE_CURRENT_SOURCE_DIR}/../../lib/libelectronic-id")
add_executable(beid-probe beid-probe.cpp)
target_compile_features(beid-probe PRIVATE cxx_std_17)
target_include_directories(beid-probe PRIVATE "${eid_library}/src/electronic-ids/pkcs11")
if(MINGW)
    target_link_options(beid-probe PRIVATE -municode -static)
endif()

enable_testing()
add_subdirectory("${eid_library}/tests/windows-module" windows-module-tests)

add_library(beid-probe-mock SHARED ../tests/mock-pkcs11.cpp)
target_include_directories(beid-probe-mock PRIVATE "${eid_library}/src/electronic-ids/pkcs11")
target_compile_features(beid-probe-mock PRIVATE cxx_std_17)
foreach(scenario enumerate require-token missing-export relative-path)
    add_test(NAME probe-${scenario}
        COMMAND ${CMAKE_COMMAND}
            -DPROBE=$<TARGET_FILE:beid-probe>
            -DMOCK=$<TARGET_FILE:beid-probe-mock>
            -DNON_PKCS11=$<TARGET_FILE:module-test-library>
            -DSCENARIO=${scenario}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/../tests/probe.cmake)
endforeach()
