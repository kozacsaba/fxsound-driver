include_guard(GLOBAL)

set(FXVAD_ID "audiosink"
    CACHE STRING
    "Machine-readable driver identity"
)

set(FXVAD_DISPLAY_NAME "AudioSink"
    CACHE STRING
    "Human-readable driver/product name"
)

set(FXVAD_ICON ""
    CACHE FILEPATH
    "Optional driver icon; empty uses the existing FxSound icon"
)

set(FXVAD_SPEAKER_GUID "{6518B5E9-772E-48E2-B110-1752F65934E8}"
    CACHE STRING
    "Stable product-specific speaker media category GUID"
)

set(FXVAD_WEBSITE ""
    CACHE STRING
    "Optional vendor website"
)

function(configure_driver_identity target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR
            "configure_driver_identity: unknown target '${target}'"
        )
    endif()

    if(NOT FXVAD_ID MATCHES "^[A-Za-z0-9_]+$")
        message(FATAL_ERROR
            "FXVAD_ID may only contain letters, numbers and underscores"
        )
    endif()

    get_target_property(source_dir "${target}" SOURCE_DIR)
    get_target_property(binary_dir "${target}" BINARY_DIR)

    if(FXVAD_ICON)
        get_filename_component(
            DRIVER_ICON
            "${FXVAD_ICON}"
            ABSOLUTE
        )
    else()
        set(DRIVER_ICON "${source_dir}/fxsound.ico")
    endif()

    message(STATUS "Driver identity configuration:")
    message(STATUS "  FXVAD_ID = \"${FXVAD_ID}\"")
    message(STATUS "  FXVAD_DISPLAY_NAME = \"${FXVAD_DISPLAY_NAME}\"")
    message(STATUS "  FXVAD_ICON = \"${DRIVER_ICON}\"")
    message(STATUS "  FXVAD_SPEAKER_GUID = \"${FXVAD_SPEAKER_GUID}\"")
    message(STATUS "  FXVAD_WEBSITE = \"${FXVAD_WEBSITE}\"")


    string(TOUPPER "${FXVAD_ID}" DRIVER_ID_UPPER)

    set(DRIVER_ID "${FXVAD_ID}")
    set(DRIVER_DEVICE_ID "${DRIVER_ID_UPPER}")
    set(DRIVER_SERVICE_NAME "${DRIVER_ID_UPPER}")

    set(DRIVER_SYS_NAME "${FXVAD_ID}.sys")
    set(DRIVER_INF_NAME "${FXVAD_ID}.inf")

    set(DRIVER_CAT_X86_NAME "${FXVAD_ID}NTx86.cat")
    set(DRIVER_CAT_AMD64_NAME "${FXVAD_ID}NTAMD64.cat")

    set(DRIVER_DISPLAY_NAME "${FXVAD_DISPLAY_NAME}")
    set(DRIVER_DEVICE_NAME "${FXVAD_DISPLAY_NAME} Audio Enhancer")
    set(DRIVER_PROVIDER_NAME "${FXVAD_DISPLAY_NAME}")

    set(DRIVER_WAVE_NAME "${FXVAD_DISPLAY_NAME} Wave")
    set(DRIVER_TOPOLOGY_NAME "${FXVAD_DISPLAY_NAME} Topology")
    set(DRIVER_SPEAKER_NAME "${FXVAD_DISPLAY_NAME} Speakers")

    set(DRIVER_SPEAKER_GUID "${FXVAD_SPEAKER_GUID}")

    if(FXVAD_WEBSITE)
        set(DRIVER_VENDOR_WEBSITE_LINE
            "DeviceVendorWebSite,,,,\"${FXVAD_WEBSITE}\""
        )
    else()
        set(DRIVER_VENDOR_WEBSITE_LINE
            ";DeviceVendorWebSite not configured"
        )
    endif()

    file(MAKE_DIRECTORY "${binary_dir}/generated")

    set(generated_inf
        "${binary_dir}/generated/${DRIVER_INF_NAME}")

    set(generated_rc
        "${binary_dir}/generated/${DRIVER_ID}.rc")

    configure_file(
        "${source_dir}/pcmex/fxvad.inf.in"
        "${generated_inf}"
        @ONLY
    )

    configure_file(
        "${source_dir}/fxvad.rc.in"
        "${generated_rc}"
        @ONLY
    )

    set_source_files_properties(
        "${generated_inf}"
        TARGET_DIRECTORY "${target}"
        PROPERTIES
            VS_TOOL_OVERRIDE "Inf"
            VS_SETTINGS "TimeStamp=14.0.0.1"
    )

    target_sources("${target}" PRIVATE
        "${generated_inf}"
        "${generated_rc}"
    )

    set_target_properties("${target}" PROPERTIES
        OUTPUT_NAME "${DRIVER_ID}"
    )
endfunction()
