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
# Limine helper tool (optional)
# ----------------------------------------------------------------
if(BOOTLOADER STREQUAL "limine")
    include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/tools/build-limine.cmake)
endif()

# ----------------------------------------------------------------
# Subdirs
# ----------------------------------------------------------------
# add_subdirectory(abi)
add_subdirectory(boot)
add_subdirectory(kernel)
# add_subdirectory(userland)
# add_subdirectory(tests)

# ----------------------------------------------------------------
# If using Limine, build the kernel first
# ----------------------------------------------------------------
if(BOOTLOADER STREQUAL "limine")
    add_dependencies(bootloader kernel)
endif()

# ----------------------------------------------------------------
# Common tools
# ----------------------------------------------------------------
find_program(QEMU qemu-system-x86_64 DOC "Path to the QEMU x86_64 emulator")

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
        set(OVMF "/opt/homebrew/share/qemu/edk2-x86_64-code.fd")    # macOS Homebrew
    else()
        set(OVMF "OVMF.fd" CACHE FILEPATH "Path to UEFI firmware image")
    endif()
endif()

# ----------------------------------------------------------------
# Images and QEMU targets
# ----------------------------------------------------------------
if(BOOTLOADER STREQUAL "limine")
    find_program(XORRISO xorriso DOC "Path to the xorriso tool")

    if(XORRISO
       AND EXISTS ${LIMINE_DIR}/limine
       AND EXISTS ${LIMINE_DIR}/limine-bios.sys
       AND EXISTS ${LIMINE_DIR}/limine-bios-cd.bin
       AND EXISTS ${LIMINE_DIR}/limine-uefi-cd.bin
       AND EXISTS ${LIMINE_DIR}/BOOTX64.EFI)
        set(ISO ${CMAKE_BINARY_DIR}/image.iso)
        set(LIMINE_ISO_ROOT ${CMAKE_BINARY_DIR}/iso_root)
        add_custom_command(
            OUTPUT ${ISO}
            COMMAND ${CMAKE_COMMAND} -E rm -rf ${LIMINE_ISO_ROOT}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${LIMINE_ISO_ROOT}/boot/limine ${LIMINE_ISO_ROOT}/EFI/BOOT
            COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:kernel> ${LIMINE_ISO_ROOT}/boot/kernel
            COMMAND ${CMAKE_COMMAND} -E copy
                    ${CMAKE_CURRENT_SOURCE_DIR}/boot/limine/limine.conf
                    ${LIMINE_DIR}/limine-bios.sys
                    ${LIMINE_DIR}/limine-bios-cd.bin
                    ${LIMINE_DIR}/limine-uefi-cd.bin
                    ${LIMINE_ISO_ROOT}/boot/limine/
            COMMAND ${CMAKE_COMMAND} -E copy ${LIMINE_DIR}/BOOTX64.EFI ${LIMINE_ISO_ROOT}/EFI/BOOT/
            COMMAND ${XORRISO} -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin
            -no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus
            -apm-block-size 2048 --efi-boot boot/limine/limine-uefi-cd.bin
            -efi-boot-part --efi-boot-image --protective-msdos-label
            -o ${ISO} ${LIMINE_ISO_ROOT}
            COMMAND ${LIMINE_DIR}/limine bios-install ${ISO}
            DEPENDS kernel ${CMAKE_CURRENT_SOURCE_DIR}/boot/limine/limine.conf
            VERBATIM)
        add_custom_target(iso DEPENDS ${ISO})
    else()
        message(WARNING "Limine ISO target disabled: install xorriso and provide a complete Limine binary release")
    endif()

    if(TARGET iso AND QEMU)
        set(QEMU_ARGS -M q35 -m 512M -cdrom ${ISO} -serial stdio -no-reboot -no-shutdown -d int,cpu_reset -D ${CMAKE_BINARY_DIR}/qemu.log)

        add_custom_target(run       COMMAND ${QEMU} ${QEMU_ARGS}                  DEPENDS iso USES_TERMINAL)
        add_custom_target(run-uefi  COMMAND ${QEMU} ${QEMU_ARGS} -bios ${OVMF}    DEPENDS iso USES_TERMINAL)
        add_custom_target(debug     COMMAND ${QEMU} ${QEMU_ARGS} -s -S            DEPENDS iso USES_TERMINAL)
    endif()
elseif(BOOTLOADER STREQUAL "bios" AND QEMU)
    set(QEMU_COMMON_ARGS -M q35 -m 512M -serial stdio -no-reboot -no-shutdown)

    add_custom_target(run
        COMMAND ${QEMU} ${QEMU_COMMON_ARGS} -drive format=raw,file=${MILLI_BIOS_IMAGE}
        DEPENDS bios_image
        USES_TERMINAL)
    add_custom_target(debug
        COMMAND ${QEMU} ${QEMU_COMMON_ARGS} -drive format=raw,file=${MILLI_BIOS_IMAGE} -s -S
        DEPENDS bios_image
        USES_TERMINAL)
elseif(BOOTLOADER STREQUAL "uefi" AND QEMU)
    set(QEMU_COMMON_ARGS -M q35 -m 512M -serial stdio -no-reboot -no-shutdown)

    add_custom_target(run
        COMMAND ${QEMU} ${QEMU_COMMON_ARGS} -bios ${OVMF} -drive format=raw,file=${MILLI_UEFI_ESP_IMAGE}
        DEPENDS uefi_image
        USES_TERMINAL)
    add_custom_target(debug
        COMMAND ${QEMU} ${QEMU_COMMON_ARGS} -bios ${OVMF} -drive format=raw,file=${MILLI_UEFI_ESP_IMAGE} -s -S
        DEPENDS uefi_image
        USES_TERMINAL)
endif()
