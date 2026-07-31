include_guard(GLOBAL)

function(_wdk_copy_asset asset_name output_file)
    set(asset_file "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/wdk/${asset_name}")

    if(NOT EXISTS "${asset_file}")
        message(FATAL_ERROR "Missing WDK build asset: ${asset_file}")
    endif()

    configure_file(
        "${asset_file}"
        "${output_file}"
        COPYONLY
    )
endfunction()

function(configure_wdm_driver target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "configure_wdm_driver: unknown target '${target}'")
    endif()

    set(props_file "${CMAKE_CURRENT_BINARY_DIR}/${target}.wdk.props")
    set(targets_file "${CMAKE_CURRENT_BINARY_DIR}/${target}.wdk.targets")

    _wdk_copy_asset(driver.props "${props_file}")
    _wdk_copy_asset(driver.targets "${targets_file}")

    set_target_properties("${target}" PROPERTIES
        VS_CONFIGURATION_TYPE "Driver"
        VS_PLATFORM_TOOLSET "WindowsKernelModeDriver10.0"

        VS_GLOBAL_DriverType "WDM"
        VS_GLOBAL_TargetVersion "Windows10"
        VS_GLOBAL_DriverTargetPlatform "Desktop"
        VS_GLOBAL_Inf2CatWindowsVersionList "10_X64"

        VS_USE_DEBUG_LIBRARIES "$<CONFIG:Debug>"
        VS_USER_PROPS "${props_file}"

        MSVC_RUNTIME_LIBRARY ""
        MSVC_RUNTIME_CHECKS ""

        PREFIX ""
        SUFFIX ".sys"
    )

    # CMake otherwise enables normal user-mode manifest generation.
    target_link_options("${target}" PRIVATE "/MANIFEST:NO")

    # Reproduce the libraries used by the original WDK project.
    #
    # CMake writes its own AdditionalDependencies element, which replaces
    # the libraries normally inherited from the WDK property sheets.
    target_link_libraries("${target}" PRIVATE
        BufferOverflowFastFailK.lib
        ntoskrnl.lib
        hal.lib
        wmilib.lib
        portcls.lib
        stdunk.lib

        # Imported into the generated Visual Studio project as an
        # MSBuild .targets file.
        "${targets_file}"
    )
endfunction()

function(add_wdk_driver_package package_target driver_target)
    if(NOT TARGET "${driver_target}")
        message(FATAL_ERROR
            "add_wdk_driver_package: unknown driver target "
            "'${driver_target}'"
        )
    endif()

    add_custom_target("${package_target}" ALL)
    add_dependencies("${package_target}" "${driver_target}")

    set(props_file "${CMAKE_CURRENT_BINARY_DIR}/${package_target}.wdk.props")

    _wdk_copy_asset(package.props "${props_file}")

    set_target_properties("${package_target}" PROPERTIES
        VS_CONFIGURATION_TYPE "Utility"
        VS_PLATFORM_TOOLSET "WindowsKernelModeDriver10.0"

        VS_GLOBAL_DriverType "Package"
        VS_GLOBAL_TargetVersion "Windows10"
        VS_GLOBAL_DisableFastUpToDateCheck "true"
        VS_GLOBAL_ImportToStore "False"
        VS_GLOBAL_InstallMode "None"

        VS_USE_DEBUG_LIBRARIES "$<CONFIG:Debug>"
        VS_USER_PROPS "${props_file}"

        FOLDER "Package"
    )
endfunction()
