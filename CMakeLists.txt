cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

project(Zeek-Plugin-Matchy)

file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" VERSION LIMIT_COUNT 1)

string(REGEX REPLACE "[.-]" " " version_numbers ${VERSION})
separate_arguments(version_numbers)
list(GET version_numbers 0 VERSION_MAJOR)
list(GET version_numbers 1 VERSION_MINOR)
list(GET version_numbers 2 VERSION_PATCH)

# Try to find zeek-config and set CMAKE_MODULE_PATH automatically
find_program(ZEEK_CONFIG zeek-config)
if(ZEEK_CONFIG)
    execute_process(
        COMMAND ${ZEEK_CONFIG} --cmake_dir
        OUTPUT_VARIABLE ZEEK_CMAKE_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE ZEEK_CONFIG_RESULT
    )
    if(ZEEK_CONFIG_RESULT EQUAL 0)
        list(APPEND CMAKE_MODULE_PATH ${ZEEK_CMAKE_DIR})
        message(STATUS "Found Zeek CMake modules: ${ZEEK_CMAKE_DIR}")
    endif()
endif()

# Option to build Matchy automatically
option(BUILD_MATCHY "Build Matchy library from source" ON)

if(BUILD_MATCHY)
    message(STATUS "Building Matchy from source...")
    
    # Check for cargo
    find_program(CARGO_EXECUTABLE cargo)
    if(NOT CARGO_EXECUTABLE)
        message(FATAL_ERROR "cargo not found. Please install Rust: https://rustup.rs")
    endif()
    
    # Check for cargo-c
    execute_process(
        COMMAND ${CARGO_EXECUTABLE} install --list
        OUTPUT_VARIABLE CARGO_INSTALLED
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    if(NOT CARGO_INSTALLED MATCHES "cargo-c")
        message(STATUS "Installing cargo-c...")
        execute_process(
            COMMAND ${CARGO_EXECUTABLE} install cargo-c
            RESULT_VARIABLE CARGO_C_INSTALL_RESULT
        )
        if(NOT CARGO_C_INSTALL_RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to install cargo-c")
        endif()
    endif()
    
    # Directories
    set(MATCHY_SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/matchy-src")
    set(MATCHY_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/matchy-install")
    
    # Clone matchy from GitHub if not already present
    if(NOT EXISTS "${MATCHY_SOURCE_DIR}/.git")
        message(STATUS "Cloning Matchy repository...")
        find_program(GIT_EXECUTABLE git)
        if(NOT GIT_EXECUTABLE)
            message(FATAL_ERROR "git not found. Please install git.")
        endif()
        execute_process(
            COMMAND ${GIT_EXECUTABLE} clone --depth 1 https://github.com/sethhall/matchy.git "${MATCHY_SOURCE_DIR}"
            RESULT_VARIABLE GIT_RESULT
        )
        if(NOT GIT_RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to clone Matchy repository")
        endif()
    endif()
    
    # Build Matchy using cargo-c
    message(STATUS "Building Matchy library (this may take a few minutes on first build)...")
    execute_process(
        COMMAND ${CARGO_EXECUTABLE} cinstall --release --prefix=${MATCHY_INSTALL_DIR}
        WORKING_DIRECTORY "${MATCHY_SOURCE_DIR}"
        RESULT_VARIABLE MATCHY_BUILD_RESULT
    )
    
    if(NOT MATCHY_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to build Matchy library")
    endif()
    
    set(MATCHY_INCLUDE_DIR "${MATCHY_INSTALL_DIR}/include")
    set(MATCHY_LIBRARY "${MATCHY_INSTALL_DIR}/lib/libmatchy.a")
    
    message(STATUS "Built Matchy include: ${MATCHY_INCLUDE_DIR}")
    message(STATUS "Built Matchy library: ${MATCHY_LIBRARY}")
else()
    # Find existing Matchy library
    find_path(MATCHY_INCLUDE_DIR
        NAMES matchy/matchy.h
        HINTS ENV MATCHY_ROOT
        PATH_SUFFIXES include
    )
    
    find_library(MATCHY_LIBRARY
        NAMES matchy
        HINTS ENV MATCHY_ROOT
        PATH_SUFFIXES lib lib64 target/release
    )
    
    if(NOT MATCHY_INCLUDE_DIR OR NOT MATCHY_LIBRARY)
        message(FATAL_ERROR "Matchy library not found. Set MATCHY_ROOT environment variable or enable BUILD_MATCHY.")
    endif()
    
    message(STATUS "Found Matchy include: ${MATCHY_INCLUDE_DIR}")
    message(STATUS "Found Matchy library: ${MATCHY_LIBRARY}")
endif()

# Load ZeekPlugin module
include(ZeekPlugin)

include_directories(BEFORE ${MATCHY_INCLUDE_DIR})

zeek_plugin_begin(Matchy DB)

# Add C++ source files
zeek_plugin_cc(src/Plugin.cc)

# Add BIF files
zeek_plugin_bif(src/matchy.bif)

# Add Zeek scripts
zeek_plugin_scripts(
    scripts/__load__.zeek
    scripts/main.zeek
)

zeek_plugin_dist_files(README.md VERSION LICENSE)

# Link against matchy library
zeek_plugin_link_library(${MATCHY_LIBRARY})

zeek_plugin_end()
