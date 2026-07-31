cmake_minimum_required(VERSION 4.2)

# WDK package projects cannot consume CMake's ZERO_CHECK helper project.
# CMake must be reconfigured manually after changing build files.
set(CMAKE_SUPPRESS_REGENERATION ON)

# Kernel drivers must not inherit the normal user-mode MSVC runtime selection
# or Debug runtime checks from CMake.
set(CMAKE_MSVC_RUNTIME_LIBRARY "")
set(CMAKE_MSVC_RUNTIME_CHECKS "")

project(fxsound_driver VERSION 14.1.0 LANGUAGES CXX RC)

# A WDM driver must not link CMake's normal user-mode Windows libraries.
set(CMAKE_CXX_STANDARD_LIBRARIES "")

if(MSVC)
    # CMake assumes a normal user-mode C++ target and enables /EHsc.
    # This WDM driver does not use C++ exceptions.
    string(REPLACE "/EHsc" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
endif()

if(NOT CMAKE_GENERATOR MATCHES "^Visual Studio")
    message(FATAL_ERROR
        "This driver currently requires a Visual Studio generator because it "
        "uses the WDK WindowsKernelModeDriver10.0 platform toolset.")
endif()

if(NOT MSVC)
    message(FATAL_ERROR "This driver requires the Microsoft C++ toolchain.")
endif()

if(NOT CMAKE_VS_PLATFORM_NAME STREQUAL "x64")
    message(FATAL_ERROR
        "Only the validated x64 driver build is currently supported. "
        "Configure with the vs2026-x64 preset.")
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(WindowsDriver)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

add_subdirectory(fxvad)

set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT fxvad_package)
