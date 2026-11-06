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
# The selected toolchain declares the target processor.
set(ARCHITECTURE "${CMAKE_SYSTEM_PROCESSOR}")

set(BOOTLOADER "bios" CACHE STRING "Boot path to build and run: bios or uefi")
set_property(CACHE BOOTLOADER PROPERTY STRINGS bios uefi)

set(RUN_HEADLESS OFF CACHE BOOL "Run qemu run and run-debug fully headless")

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
find_program(QEMU qemu-system-${ARCHITECTURE} DOC "Path to the QEMU ${ARCHITECTURE} emulator")

if(NOT QEMU)
    message(WARNING "run and run-debug targets are not available because qemu cannot be found on your system.")
endif()

find_program(DD dd REQUIRED)
find_program(PARTED parted REQUIRED)
find_program(MKFS_FAT mkfs.fat REQUIRED)
find_program(MCOPY mcopy REQUIRED)
find_program(MMD mmd REQUIRED)

# ----------------------------------------------------------------
# Combine bootloader, initrd & kernel into image
# FUTURE TODO: Add initrd cpio
# ----------------------------------------------------------------
set(MILLI_IMAGE_SIZE_MIB 64 CACHE STRING "Size of generated disk images in MiB")
set(MILLI_PARTITION_START_SECTOR 2048)

math(EXPR MILLI_PARTITION_OFFSET_BYTES "${MILLI_PARTITION_START_SECTOR} * 512") # Each sector is 512 bytes

if(BOOTLOADER STREQUAL "bios")
    set(MILLI_BIOS_IMAGE "${CMAKE_BINARY_DIR}/milli-bios.img")

    add_custom_command(
        OUTPUT "${MILLI_BIOS_IMAGE}"
        COMMAND ${DD} if=/dev/zero of=${MILLI_BIOS_IMAGE} bs=1048576 count=${MILLI_IMAGE_SIZE_MIB}
        COMMAND ${PARTED} --script ${MILLI_BIOS_IMAGE}
            mklabel msdos
            mkpart primary fat32 1MiB 100%
            set 1 boot on
        COMMAND ${MKFS_FAT} --offset=${MILLI_PARTITION_START_SECTOR} -F 32 ${MILLI_BIOS_IMAGE}
        COMMAND ${MMD} -i ${MILLI_BIOS_IMAGE}@@${MILLI_PARTITION_OFFSET_BYTES} ::/BOOT
        COMMAND ${MCOPY} -i ${MILLI_BIOS_IMAGE}@@${MILLI_PARTITION_OFFSET_BYTES}
            $<TARGET_FILE:kernel_elf> ::/BOOT/KERNEL.ELF
        # COMMAND ${MCOPY} -i ${MILLI_BIOS_IMAGE}@@${MILLI_PARTITION_OFFSET_BYTES}
        #     ${INITRD_CPIO} ::/BOOT/INITRD.CPI
        COMMAND ${DD} if=${BIOS_STAGE2_BIN} of=${MILLI_BIOS_IMAGE} bs=512 seek=1 conv=notrunc
        COMMAND ${DD} if=${BIOS_STAGE1_BIN} of=${MILLI_BIOS_IMAGE} bs=446 count=1 conv=notrunc
        DEPENDS
            bootloader_bios_stage1_bin
            bootloader_bios_stage2_bin
            kernel_elf
            # ${INITRD_CPIO}
        VERBATIM
    )

    add_custom_target(bios_image ALL DEPENDS "${MILLI_BIOS_IMAGE}")
elseif(BOOTLOADER STREQUAL "uefi")
    set(MILLI_UEFI_IMAGE "${CMAKE_BINARY_DIR}/milli-uefi.img")

    add_custom_command(
        OUTPUT "${MILLI_UEFI_IMAGE}"
        COMMAND ${DD} if=/dev/zero of=${MILLI_UEFI_IMAGE} bs=1048576 count=${MILLI_IMAGE_SIZE_MIB}
        COMMAND ${PARTED} --script ${MILLI_UEFI_IMAGE}
            mklabel gpt
            mkpart ESP fat32 1MiB 100%
            set 1 esp on
        COMMAND ${MKFS_FAT} --offset=${MILLI_PARTITION_START_SECTOR} -F 32 ${MILLI_UEFI_IMAGE}
        COMMAND ${MMD} -i ${MILLI_UEFI_IMAGE}@@${MILLI_PARTITION_OFFSET_BYTES} ::/EFI
        COMMAND ${MMD} -i ${MILLI_UEFI_IMAGE}@@${MILLI_PARTITION_OFFSET_BYTES} ::/EFI/BOOT
        COMMAND ${MMD} -i ${MILLI_UEFI_IMAGE}@@${MILLI_PARTITION_OFFSET_BYTES} ::/BOOT
        COMMAND ${MCOPY} -i ${MILLI_UEFI_IMAGE}@@${MILLI_PARTITION_OFFSET_BYTES}
            ${UEFI_EFI_FILE} ::/EFI/BOOT/BOOTX64.EFI
        COMMAND ${MCOPY} -i ${MILLI_UEFI_IMAGE}@@${MILLI_PARTITION_OFFSET_BYTES}
            $<TARGET_FILE:kernel_elf> ::/BOOT/KERNEL.ELF
        # COMMAND ${MCOPY} -i ${MILLI_UEFI_IMAGE}@@${MILLI_PARTITION_OFFSET_BYTES}
        #     ${INITRD_CPIO} ::/BOOT/INITRD.CPI
        DEPENDS
            bootloader_uefi_efi
            kernel_elf
            # ${INITRD_CPIO}
        VERBATIM
    )

    add_custom_target(uefi_image ALL DEPENDS "${MILLI_UEFI_IMAGE}")
endif()

# ----------------------------------------------------------------
# Create run and run-debug targets (arch specific)
# ----------------------------------------------------------------
if(QEMU)
    if(ARCHITECTURE STREQUAL "x86_64")
        set(QEMU_COMMON_ARGS -M q35 -m 512M -serial stdio -no-reboot -no-shutdown)
        if(RUN_HEADLESS)
            list(APPEND QEMU_COMMON_ARGS -display none)
        endif()

        if(BOOTLOADER STREQUAL "bios")
            set(MILLI_IMAGE "${MILLI_BIOS_IMAGE}")
            set(MILLI_IMAGE_TARGET bios_image)
            set(MILLI_QEMU_BOOT_ARGS -drive format=raw,file=${MILLI_IMAGE})
        elseif(BOOTLOADER STREQUAL "uefi")
            # OVMF is the x86_64 UEFI firmware used by qemu-system-x86_64.
            set(OVMF "" CACHE FILEPATH "Path to UEFI firmware image (OVMF.fd)")
            if(NOT OVMF)
                if(EXISTS "/usr/share/ovmf/OVMF.fd")
                    set(OVMF "/usr/share/ovmf/OVMF.fd" CACHE FILEPATH "Path to UEFI firmware image (OVMF.fd)" FORCE) # Ubuntu/Debian
                elseif(EXISTS "/usr/share/edk2/ovmf/OVMF_CODE.fd")
                    set(OVMF "/usr/share/edk2/ovmf/OVMF_CODE.fd" CACHE FILEPATH "Path to UEFI firmware image (OVMF.fd)" FORCE) # Fedora
                elseif(EXISTS "/usr/share/edk2/x64/OVMF_CODE.fd")
                    set(OVMF "/usr/share/edk2/x64/OVMF_CODE.fd" CACHE FILEPATH "Path to UEFI firmware image (OVMF.fd)" FORCE) # Arch
                elseif(EXISTS "/opt/homebrew/share/qemu/edk2-x86_64-code.fd")
                    set(OVMF "/opt/homebrew/share/qemu/edk2-x86_64-code.fd" CACHE FILEPATH "Path to UEFI firmware image (OVMF.fd)" FORCE) # macOS Homebrew
                else()
                    message(FATAL_ERROR
                        "No x86_64 OVMF firmware was found. Install OVMF or configure with "
                        "-DOVMF=/path/to/OVMF_CODE.fd.")
                endif()
            endif()

            set(MILLI_IMAGE "${MILLI_UEFI_IMAGE}")
            set(MILLI_IMAGE_TARGET uefi_image)
            set(MILLI_QEMU_BOOT_ARGS -bios ${OVMF} -drive format=raw,file=${MILLI_IMAGE})
        endif()
    else()
        message(FATAL_ERROR "No QEMU run configuration exists for ARCHITECTURE=${ARCHITECTURE}.")
    endif()

    add_custom_target(run
        COMMAND ${QEMU} ${QEMU_COMMON_ARGS} ${MILLI_QEMU_BOOT_ARGS}
        DEPENDS ${MILLI_IMAGE_TARGET}
        USES_TERMINAL
    )
    add_custom_target(run-debug
        COMMAND ${QEMU} ${QEMU_COMMON_ARGS} ${MILLI_QEMU_BOOT_ARGS} -s -S
        DEPENDS ${MILLI_IMAGE_TARGET}
        USES_TERMINAL
    )
endif()
