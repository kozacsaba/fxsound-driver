include_guard(GLOBAL)

function(_wdk_write_driver_props output_file)
    file(WRITE "${output_file}" [=[<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="Current" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props"
          Condition="exists('$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props')" />
  <ItemDefinitionGroup>
    <ClCompile>
      <AdditionalIncludeDirectories>$(DDK_INC_PATH);%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>
    </ClCompile>
    <ResourceCompile>
      <AdditionalIncludeDirectories>$(DDK_INC_PATH);%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>
    </ResourceCompile>
    <DriverSign>
      <AdditionalOptions>/fd SHA256 %(AdditionalOptions)</AdditionalOptions>
    </DriverSign>
  </ItemDefinitionGroup>
</Project>
]=])
endfunction()

function(_wdk_write_package_props output_file)
    file(WRITE "${output_file}" [=[<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="Current" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props"
          Condition="exists('$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props')" />
  <ItemDefinitionGroup>
    <DriverSign>
      <AdditionalOptions>/fd SHA256 %(AdditionalOptions)</AdditionalOptions>
    </DriverSign>
  </ItemDefinitionGroup>
</Project>
]=])
endfunction()

function(_wdk_write_driver_targets output_file)
    file(WRITE "${output_file}" [=[<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="Current"
         xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemGroup>
    <FilesToPackage
        Include="$(TargetPath)"
        Condition="'$(ConfigurationType)' == 'Driver'" />
  </ItemGroup>
</Project>
]=])
endfunction()

function(configure_wdm_driver target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR
            "configure_wdm_driver: unknown target '${target}'")
    endif()

    set(props_file "${CMAKE_CURRENT_BINARY_DIR}/${target}.wdk.props")
    set(targets_file "${CMAKE_CURRENT_BINARY_DIR}/${target}.wdk.targets")

    _wdk_write_driver_props("${props_file}")
    _wdk_write_driver_targets("${targets_file}")

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
    target_link_options("${target}" PRIVATE
        "/MANIFEST:NO"
    )

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

        # CMake imports full paths ending in .targets into the VS project.
        "${targets_file}"
    )
endfunction()

function(add_wdk_driver_package package_target driver_target)
    if(NOT TARGET "${driver_target}")
        message(FATAL_ERROR
            "add_wdk_driver_package: unknown driver target '${driver_target}'")
    endif()

    add_custom_target("${package_target}" ALL)
    add_dependencies("${package_target}" "${driver_target}")

    set(props_file "${CMAKE_CURRENT_BINARY_DIR}/${package_target}.wdk.props")
    _wdk_write_package_props("${props_file}")

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
