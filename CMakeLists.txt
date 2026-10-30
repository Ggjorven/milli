cmake_minimum_required(VERSION 3.21)

# ----------------------------------------------------------------
# Global
# ----------------------------------------------------------------
project(milli LANGUAGES CXX C)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "" FORCE)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ----------------------------------------------------------------
# Options
# ----------------------------------------------------------------
option(BUILD_WITH_LIMINE "Build a bootable ISO image using Limine" OFF)

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
# Build limine helper tool (optional)
# ----------------------------------------------------------------
if(BUILD_WITH_LIMINE)
    set(LIMINE_BRANCH "v11.x-binary" CACHE STRING "Limine binary-release branch/tag to fetch")
    set(LIMINE_DIR    "" CACHE PATH "Existing Limine binary checkout (empty = fetch it)")

    if(NOT LIMINE_DIR)
        include(FetchContent)
        FetchContent_Declare(limine
            GIT_REPOSITORY https://github.com/limine-bootloader/limine.git
            GIT_TAG        ${LIMINE_BRANCH}
            GIT_SHALLOW    TRUE
            SOURCE_SUBDIR  _no_cmake_here
        )
        FetchContent_MakeAvailable(limine)
        set(LIMINE_DIR ${limine_SOURCE_DIR})
    endif()

    find_program(MAKE_TOOL NAMES make gmake)
    if(NOT EXISTS ${LIMINE_DIR}/limine AND EXISTS ${LIMINE_DIR}/Makefile AND MAKE_TOOL)
        execute_process(COMMAND ${MAKE_TOOL} -C ${LIMINE_DIR} RESULT_VARIABLE _exit_code)
        if(NOT _exit_code EQUAL 0)
            message(WARNING "Building the limine tool failed; the 'iso' target won't work")
        endif()
    endif()
endif()

# ----------------------------------------------------------------
# Subdirs
# ----------------------------------------------------------------
# add_subdirectory(abi)
add_subdirectory(boot)
# add_subdirectory(kernel)
# add_subdirectory(userland)
# add_subdirectory(tests)

# ----------------------------------------------------------------
# Common tools
# ----------------------------------------------------------------
find_program(QEMU qemu-system-x86_64 DOC "Path to the QEMU x86_64 emulator")

# Cross-platform OVMF UEFI firmware auto-discovery
set(OVMF "" CACHE FILEPATH "Path to UEFI firmware image (OVMF.fd)")
if(NOT OVMF)
    if(EXISTS "/usr/share/ovmf/OVMF.fd")
        set(OVMF "/usr/share/ovmf/OVMF.fd")                         # Ubuntu/Debian
    elseif(EXISTS "/usr/share/edk2/x64/OVMF_CODE.fd")
        set(OVMF "/usr/share/edk2/x64/OVMF_CODE.fd")                # Fedora/Arch
    elseif(EXISTS "/opt/homebrew/share/qemu/edk2-x86_64-code.fd")
        set(OVMF "/opt/homebrew/share/qemu/edk2-x86_64-code.fd")    # macOS Homebrew
    else()
        set(OVMF "OVMF.fd" CACHE FILEPATH "Path to UEFI firmware image")
    endif()
endif()

# ----------------------------------------------------------------
# Option 1: Build with custom bootloader
# ----------------------------------------------------------------
if(NOT BUILD_WITH_LIMINE)
    # TODO: Custom bootloader image generation logic here
    # (e.g. combining custom bootloader binary from add_subdirectory(boot) with kernel)

    set(IMAGE ${CMAKE_BINARY_DIR}/image.img)

    # TODO: Add a custom command that depends on custom bootloader and kernel targets
    # add_custom_command(OUTPUT ${CUSTOM_IMAGE} ... COMMAND ...)
    # add_custom_target(custom_img DEPENDS ${CUSTOM_IMAGE})

    if(QEMU)
        set(QEMU_CUSTOM_ARGS -M q35 -m 512M -drive format=raw,file=${CUSTOM_IMAGE} -serial stdio -no-reboot -no-shutdown -d int,cpu_reset -D ${CMAKE_BINARY_DIR}/qemu_custom.log)

        add_custom_target(run       COMMAND ${QEMU} ${QEMU_CUSTOM_ARGS}                 USES_TERMINAL)
        add_custom_target(run-uefi  COMMAND ${QEMU} ${QEMU_CUSTOM_ARGS} -bios ${OVMF}   USES_TERMINAL)
        add_custom_target(debug     COMMAND ${QEMU} ${QEMU_CUSTOM_ARGS} -s -S           USES_TERMINAL)
    endif()

# ----------------------------------------------------------------
# Option 2: Build with limine
# ----------------------------------------------------------------
else()
    find_program(XORRISO xorriso DOC "Path to the xorriso tool")

    if(XORRISO AND EXISTS ${LIMINE_DIR}/limine)
        set(ISO ${CMAKE_BINARY_DIR}/image.iso)
        add_custom_command(
            OUTPUT ${ISO}
            COMMAND ${CMAKE_COMMAND} -E rm -rf iso_root
            COMMAND ${CMAKE_COMMAND} -E make_directory iso_root/boot/limine iso_root/EFI/BOOT
            COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:kernel> iso_root/boot/kernel
            COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/kernel/limine.conf
            ${LIMINE_DIR}/limine-bios.sys ${LIMINE_DIR}/limine-bios-cd.bin
            ${LIMINE_DIR}/limine-uefi-cd.bin iso_root/boot/limine/
            COMMAND ${CMAKE_COMMAND} -E copy ${LIMINE_DIR}/BOOTX64.EFI ${LIMINE_DIR}/BOOTIA32.EFI
            iso_root/EFI/BOOT/
            COMMAND ${XORRISO} -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin
            -no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus
            -apm-block-size 2048 --efi-boot boot/limine/limine-uefi-cd.bin
            -efi-boot-part --efi-boot-image --protective-msdos-label
            iso_root -o ${ISO}
            COMMAND ${LIMINE_DIR}/limine bios-install ${ISO}
            DEPENDS kernel ${CMAKE_CURRENT_SOURCE_DIR}/kernel/limine.conf
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
            VERBATIM)
        add_custom_target(iso DEPENDS ${ISO})
    endif()

    if(TARGET iso AND QEMU)
        set(QEMU_ARGS -M q35 -m 512M -cdrom ${ISO} -serial stdio -no-reboot -no-shutdown -d int,cpu_reset -D ${CMAKE_BINARY_DIR}/qemu.log)

        add_custom_target(run       COMMAND ${QEMU} ${QEMU_ARGS}                  DEPENDS iso USES_TERMINAL)
        add_custom_target(run-uefi  COMMAND ${QEMU} ${QEMU_ARGS} -bios ${OVMF}    DEPENDS iso USES_TERMINAL)
        add_custom_target(debug     COMMAND ${QEMU} ${QEMU_ARGS} -s -S            DEPENDS iso USES_TERMINAL)
    endif()
endif()