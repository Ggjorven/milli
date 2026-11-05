cmake_minimum_required(VERSION 3.21)

# ----------------------------------------------------------------
# Global
# ----------------------------------------------------------------
project(milli LANGUAGES C ASM)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "" FORCE)
endif()

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ----------------------------------------------------------------
# Options
# ----------------------------------------------------------------
set(ARCHITECTURE "x86_64" CACHE STRING "Target architecture")
set_property(CACHE ARCHITECTURE PROPERTY STRINGS x86_64)

set(BOOTLOADER "bios" CACHE STRING "Boot path to build and run: bios or uefi")
set_property(CACHE BOOTLOADER PROPERTY STRINGS bios uefi)

# ----------------------------------------------------------------
# Checks
# ----------------------------------------------------------------
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    message(FATAL_ERROR
        "\n======================================================================\n"
        "ERROR: milli cannot be built using native Windows (MSVC or MinGW)!\n"
        "This is because we require certain tools that not available on Windows like xorriso.\n\n"
        "Please open this project inside WSL2 (Windows Subsystem for Linux)\n"
        "or use a Linux/macOS host system to configure and build.\n"
        "======================================================================\n"
    )
endif()

set(SUPPORTED_ARCHITECTURES x86_64)
if(NOT ARCHITECTURE IN_LIST SUPPORTED_ARCHITECTURES)
    message(FATAL_ERROR
        "Invalid ARCHITECTURE='${ARCHITECTURE}'. Choose: ${SUPPORTED_ARCHITECTURES}.")
endif()

set(SUPPORTED_BOOTLOADERS bios uefi)
if(NOT BOOTLOADER IN_LIST SUPPORTED_BOOTLOADERS)
    message(FATAL_ERROR "Invalid BOOTLOADER='${BOOTLOADER}'. Choose bios or uefi.")
endif()

if(BOOTLOADER STREQUAL "bios" AND NOT ARCHITECTURE STREQUAL "x86_64")
    message(FATAL_ERROR
        "BOOTLOADER=bios requires ARCHITECTURE=x86_64, legacy BIOS is an x86-only boot path.")
endif()

# ----------------------------------------------------------------
# Subdirs
# ----------------------------------------------------------------
# add_subdirectory(abi)
add_subdirectory(boot)
# add_subdirectory(initrd) # TODO: ...
add_subdirectory(kernel)
# add_subdirectory(userland)
# add_subdirectory(tests)
