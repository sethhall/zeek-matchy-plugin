cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

project(Zeek-Plugin-Matchy)

file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" VERSION LIMIT_COUNT 1)

string(REGEX REPLACE "[.-]" " " version_numbers ${VERSION})
separate_arguments(version_numbers)
list(GET version_numbers 0 VERSION_MAJOR)
list(GET version_numbers 1 VERSION_MINOR)
list(GET version_numbers 2 VERSION_PATCH)

# Find Matchy library
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
    message(FATAL_ERROR "Matchy library not found. Set MATCHY_ROOT environment variable or install matchy.")
endif()

message(STATUS "Found Matchy include: ${MATCHY_INCLUDE_DIR}")
message(STATUS "Found Matchy library: ${MATCHY_LIBRARY}")

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
