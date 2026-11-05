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

# ----------------------------------------------------------------
# Common tools
# ----------------------------------------------------------------
find_program(QEMU qemu-system-x86_64 DOC "Path to the QEMU x86_64 emulator")

if(NOT QEMU)
    message(WARNING "run and run-debug targets are not available because qemu cannot be found on your system."
endif()

# Cross-platform OVMF UEFI firmware auto-discovery
set(OVMF "" CACHE FILEPATH "Path to UEFI firmware image (OVMF.fd)")
if(NOT OVMF)
    if(EXISTS "/usr/share/ovmf/OVMF.fd")
        set(OVMF "/usr/share/ovmf/OVMF.fd")                         # Ubuntu/Debian
    elseif(EXISTS "/usr/share/edk2/ovmf/OVMF_CODE.fd")
        set(OVMF "/usr/share/edk2/ovmf/OVMF_CODE.fd")               # Fedora
    elseif(EXISTS "/usr/share/edk2/x64/OVMF_CODE.fd")
        set(OVMF "/usr/share/edk2/x64/OVMF_CODE.fd")                # Arch
    elseif(EXISTS "/opt/homebrew/share/qemu/edk2-x86_64-code.fd")
        set(OVMF "/opt/homebrew/share/qemu/edk2-x86_64-code.fd")    # MacOS Homebrew
    else()
        set(OVMF "OVMF.fd" CACHE FILEPATH "Path to UEFI firmware image")
    endif()
endif()

# ----------------------------------------------------------------
# Combine bootloader, initrd & kernel
# ----------------------------------------------------------------
if(BOOTLOADER STREQUAL "bios")

elseif(BOOTLOADER STREQUAL "uefi")

endif()

# ----------------------------------------------------------------
# Create run and run-debug targets (TODO)
# ----------------------------------------------------------------
# if(BOOTLOADER STREQUAL "bios" AND QEMU)
#     set(QEMU_COMMON_ARGS -M q35 -m 512M -serial stdio -no-reboot -no-shutdown)
#
#     add_custom_target(run
#         COMMAND ${QEMU} ${QEMU_COMMON_ARGS} -drive format=raw,file=${MILLI_BIOS_IMAGE}
#         DEPENDS bios_image
#         USES_TERMINAL)
#     add_custom_target(debug
#         COMMAND ${QEMU} ${QEMU_COMMON_ARGS} -drive format=raw,file=${MILLI_BIOS_IMAGE} -s -S
#         DEPENDS bios_image
#         USES_TERMINAL)
# elseif(BOOTLOADER STREQUAL "uefi" AND QEMU)
#     set(QEMU_COMMON_ARGS -M q35 -m 512M -serial stdio -no-reboot -no-shutdown)
#
#     add_custom_target(run
#         COMMAND ${QEMU} ${QEMU_COMMON_ARGS} -bios ${OVMF} -drive format=raw,file=${MILLI_UEFI_ESP_IMAGE}
#         DEPENDS uefi_image
#         USES_TERMINAL)
#     add_custom_target(debug
#         COMMAND ${QEMU} ${QEMU_COMMON_ARGS} -bios ${OVMF} -drive format=raw,file=${MILLI_UEFI_ESP_IMAGE} -s -S
#         DEPENDS uefi_image
#         USES_TERMINAL)
# endif()
