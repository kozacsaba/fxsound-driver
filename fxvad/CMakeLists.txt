# fxvad source

set(fxvad_sources
    adapter.cpp
    basedma.cpp
    basetopo.cpp
    basewave.cpp
    common.cpp
    hw.cpp
    kshelper.cpp
    savedata.cpp

    pcmex/mintopo.cpp
    pcmex/minwave.cpp
)

set(fxvad_headers
    basetopo.h
    basewave.h
    common.h
    hw.h
    kshelper.h
    msvad.h
    savedata.h

    pcmex/mintopo.h
    pcmex/minwave.h
    pcmex/pcmex.h
    pcmex/toptable.h
    pcmex/wavtable.h
)

add_library(fxvad_driver MODULE
    ${fxvad_sources}
    ${fxvad_headers}
)

source_group(
    TREE "${CMAKE_CURRENT_SOURCE_DIR}"
    FILES
        ${fxvad_sources}
        ${fxvad_headers}
)

target_include_directories(fxvad_driver PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
)

target_compile_definitions(fxvad_driver PRIVATE
    _WIN32
    UNICODE
    _UNICODE
    PC_IMPLEMENTATION
    DEBUG_LEVEL=DEBUGLVL_TERSE
)

# CMake normally enables user-mode C++ exception handling and RTTI for MSVC.
# The original WDM project explicitly leaves both disabled.
target_compile_options(fxvad_driver PRIVATE
    "$<$<COMPILE_LANGUAGE:CXX>:/W4>"
    "$<$<COMPILE_LANGUAGE:CXX>:/wd4996>"
    "$<$<COMPILE_LANGUAGE:CXX>:/GR->"
)

set_target_properties(fxvad_driver PROPERTIES
    COMPILE_WARNING_AS_ERROR ON
    FOLDER "Driver"
)

configure_wdm_driver(fxvad_driver)
add_wdk_driver_package(fxvad_package fxvad_driver)
