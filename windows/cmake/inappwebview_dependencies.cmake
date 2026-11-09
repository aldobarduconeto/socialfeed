find_program(NUGET NAMES nuget.exe nuget)
if(NOT NUGET)
  set(_nuget_dir "${CMAKE_BINARY_DIR}/tools/nuget/6.14.0")
  set(_nuget_exe "${_nuget_dir}/nuget.exe")
  if(NOT EXISTS "${_nuget_exe}")
    file(MAKE_DIRECTORY "${_nuget_dir}")
    message(STATUS "Downloading NuGet CLI for InAppWebView")
    file(DOWNLOAD
      "https://dist.nuget.org/win-x86-commandline/v6.14.0/nuget.exe"
      "${_nuget_exe}.download"
      TLS_VERIFY ON
      TIMEOUT 60
      STATUS _nuget_status
    )
    list(GET _nuget_status 0 _nuget_code)
    if(NOT _nuget_code EQUAL 0)
      list(GET _nuget_status 1 _nuget_error)
      message(FATAL_ERROR
        "Could not download NuGet: ${_nuget_error}. Install nuget.exe and add its directory to PATH, or pass -DNUGET=<path-to-nuget.exe>.")
    endif()
    file(SHA256 "${_nuget_exe}.download" _nuget_sha256)
    if(NOT _nuget_sha256 STREQUAL "92dbed160ddee0f64b901e907439e021211b428e57c089ecc12fc38dcc4bd9a5")
      message(FATAL_ERROR "The NuGet CLI download did not match the expected SHA-256.")
    endif()
    file(RENAME "${_nuget_exe}.download" "${_nuget_exe}")
  endif()
  set(NUGET "${_nuget_exe}" CACHE FILEPATH "NuGet CLI for InAppWebView" FORCE)
endif()

# InAppWebView 0.6.0 passes DEPENDS to add_custom_command(TARGET).
# Keep the legacy behavior until the plugin removes the unsupported argument.
if(POLICY CMP0175)
  set(CMAKE_POLICY_DEFAULT_CMP0175 OLD)
endif()
