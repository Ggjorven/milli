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
set(BOOTLOADER "bios" CACHE STRING "Boot path to build and run: limine, bios, or uefi")
set_property(CACHE BOOTLOADER PROPERTY STRINGS limine bios uefi)

set(SUPPORTED_BOOTLOADERS limine bios uefi)
if(NOT BOOTLOADER IN_LIST SUPPORTED_BOOTLOADERS)
    message(FATAL_ERROR "Invalid BOOTLOADER='${BOOTLOADER}'. Choose limine, bios, or uefi.")
endif()

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

# ----------------------------------------------------------------
# Subdirs
# ----------------------------------------------------------------
# add_subdirectory(abi)
add_subdirectory(boot)
add_subdirectory(kernel)
# add_subdirectory(userland)
# add_subdirectory(tests)
