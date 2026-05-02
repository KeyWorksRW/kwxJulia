# CMake 3.30 required for FetchContent performance improvements (CMP0168)
cmake_minimum_required(VERSION 3.30)

string( TIMESTAMP YEAR "%y" ) # e.g., "25"
string( TIMESTAMP DOY "%j" ) # e.g., "192"
string( TIMESTAMP PROJECT_YEAR "%Y" )
math( EXPR BUILD_NUM "${YEAR}%100 * 1000 + ${DOY}" )

set( PROJECT_VERSION_MAJOR 0 )
set( PROJECT_VERSION_MINOR 1 )
set( PROJECT_VERSION_PATCH 0 )
set( PROJECT_VERSION_BUILD ${BUILD_NUM} )
set( PROJECT_VERSION_YEAR ${PROJECT_YEAR} )

project( kwxJuliaFFI
    LANGUAGES C CXX
    VERSION ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}.${PROJECT_VERSION_BUILD}
    DESCRIPTION "kwxJuliaFFI - Julia bindings for wxWidgets via kwxFFI"
    HOMEPAGE_URL "https://github.com/KeyWorksRW/kwxJulia" )

# ###################### General Settings #######################
set( CMAKE_CXX_STANDARD 23 )
set( CMAKE_CXX_STANDARD_REQUIRED True )
set( CMAKE_CXX_EXTENSIONS OFF )

# Only generate compile_commands.json for local development
if(NOT DEFINED ENV{CI})
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
endif()

# ###################### Options #######################
# Force Release build (Julia FFI requires release runtime, not debug)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()
# For multi-config generators (Visual Studio, Ninja Multi-Config)
if(CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_CONFIGURATION_TYPES "Release" CACHE STRING "Available build types" FORCE)
endif()

# Only generate compile_commands.json for local development
if ( NOT DEFINED ENV{CI} )
    # creates a compile_commands.json file in the build directory, suitable for clangd
    set( CMAKE_EXPORT_COMPILE_COMMANDS ON )
endif()

# ###################### ccache support #######################
find_program( CCACHE_PROGRAM ccache )

if( CCACHE_PROGRAM )
    message( STATUS "Using ccache: ${CCACHE_PROGRAM}" )
    set( CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}" )
    set( CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}" )

    message( NOTICE "ccache detected. Configure ccache globally for your development environment:" )
    message( NOTICE "  Recommended for all platforms:" )
    message( NOTICE "    ccache --set-config=compression=true" )
    message( NOTICE "    ccache --set-config=max_size=<appropriate for your projects>" )
    message( NOTICE "    ccache --set-config=sloppiness=pch_defines,time_macros,include_file_mtime,include_file_ctime" )

    if( MSVC )
        message( NOTICE "  Required for MSVC:" )

        message( NOTICE "    ccache --set-config=pch_external_checksum=true" )
        message( NOTICE "    ccache --set-config=depend_mode=true" )
        message( NOTICE "    ccache --set-config=\"ignore_options=/Zi /Z7 /ZI /FS /Fd*\"" )
    endif()

    message( NOTICE "  Run 'ccache --show-config' to verify current settings" )
    message( NOTICE "  Run 'ccache -s' to monitor cache usage" )
endif()

include( FetchContent )

# Suppress verbose FetchContent git output (CMake 3.30+)
set(FETCHCONTENT_QUIET ON)

# Configure kwxFFI to build as a shared library (required for Julia @ccall)
set(KWXFFI_BUILD_SHARED ON CACHE BOOL "Build kwxFFI as a shared library" FORCE)

message( STATUS "Fetching kwxFFI and wxWidgets (this may take awhile) ..." )

FetchContent_Declare(
    kwxFFI
    GIT_REPOSITORY https://github.com/KeyWorksRW/kwxFFI.git
    GIT_TAG origin/main
    GIT_SHALLOW TRUE
    UPDATE_DISCONNECTED FALSE  # Explicitly enable updates
)

message( NOTICE "Configuring kwxFFI..." )

FetchContent_MakeAvailable( kwxFFI )

# Override kwxFFI output directories to place DLLs in root bin/Release directory
# Set per-config properties to prevent CMake from appending another /Release
foreach(config IN ITEMS RELEASE DEBUG MINSIZEREL RELWITHDEBINFO)
    set_target_properties( kwxFFI PROPERTIES
        OUTPUT_NAME "kwxJuliaFFI"
        PREFIX ""
        ARCHIVE_OUTPUT_DIRECTORY_${config} "${CMAKE_BINARY_DIR}/import_libs"
        LIBRARY_OUTPUT_DIRECTORY_${config} "${PROJECT_SOURCE_DIR}/bin/Release"
        RUNTIME_OUTPUT_DIRECTORY_${config} "${PROJECT_SOURCE_DIR}/bin/Release"
    )
endforeach()

message( NOTICE "kwxFFI has been fetched and configured." )
message( STATUS "kwxFFI sources: " ${kwxFFI_SOURCE_DIR} )

# ###################### kwxgen — Julia binding generator #######################

add_subdirectory( ${kwxFFI_SOURCE_DIR}/tools/kwxgen kwxgen-build )

set( KWXFFI_HEADERS
    ${kwxFFI_SOURCE_DIR}/include/kwx_classes.h
    ${kwxFFI_SOURCE_DIR}/include/kwx_events.h
    ${kwxFFI_SOURCE_DIR}/include/kwx_keys.h
    ${kwxFFI_SOURCE_DIR}/include/kwx_constants.h
)

add_custom_command(
    OUTPUT  ${CMAKE_SOURCE_DIR}/wx/events_gen.jl
            ${CMAKE_SOURCE_DIR}/wx/keys_gen.jl
            ${CMAKE_SOURCE_DIR}/wx/constants_gen.jl
            ${CMAKE_SOURCE_DIR}/wx/classes_gen.jl
            ${CMAKE_SOURCE_DIR}/wx/freefuncs_gen.jl
            ${CMAKE_SOURCE_DIR}/wx/KwxFFI_gen.jl
    COMMAND kwxgen generate
                --headers ${kwxFFI_SOURCE_DIR}/include
                --defs    ${kwxFFI_SOURCE_DIR}/src/kwx_defs.cpp
                --lang    julia
                --libname kwxJuliaFFI
                --out     ${CMAKE_SOURCE_DIR}/wx/
    DEPENDS kwxgen ${KWXFFI_HEADERS}
    COMMENT "Generating Julia bindings via kwxgen"
)

add_custom_target( generate_julia_bindings ALL
    DEPENDS
        ${CMAKE_SOURCE_DIR}/wx/events_gen.jl
        ${CMAKE_SOURCE_DIR}/wx/keys_gen.jl
        ${CMAKE_SOURCE_DIR}/wx/constants_gen.jl
        ${CMAKE_SOURCE_DIR}/wx/classes_gen.jl
        ${CMAKE_SOURCE_DIR}/wx/freefuncs_gen.jl
        ${CMAKE_SOURCE_DIR}/wx/KwxFFI_gen.jl
)

# Define wxWidgets paths (kwxFFI fetches wxWidgets as a subdependency)
# These match the FetchContent directory structure
set( WX_SRC_DIR ${CMAKE_BINARY_DIR}/_deps/wxwidgets-src )
set( WX_BUILD_DIR ${CMAKE_BINARY_DIR}/_deps/wxwidgets-build )
message( STATUS "wxWidgets sources: " ${WX_SRC_DIR} )
message( STATUS "wxWidgets build: " ${WX_BUILD_DIR} )

# ###################### kwxApp - compiled into kwxFFI #######################
# Add kwxApp.cpp directly to the kwxFFI target so it shares the same wxWidgets
# runtime. Building it as a separate DLL causes dual-runtime issues because
# wxWidgets is statically linked (wxBUILD_SHARED=OFF): each DLL gets its own
# copy of wxTheApp, wxTopLevelWindows, event dispatch, etc., which means the
# event loop in one DLL cannot see windows created through the other.
#
# kwxApp.cpp uses SHARED_LIBRARY (already defined on the kwxFFI target) to
# gate __declspec(dllexport), so these functions become part of kwxffi.dll.

target_sources( kwxFFI PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/cpp/kwxApp.cpp
)

# kwxApp.cpp needs wxWidgets headers (already on kwxFFI's include path)
# and the kwxFFI include directory for wrapper.h (also already set).
# No additional include_directories or link_libraries needed.
