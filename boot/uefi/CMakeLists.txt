# ----------------------------------------------------------------
# Checks
# ----------------------------------------------------------------
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/arch/${ARCHITECTURE}/CMakeLists.txt")
    message(FATAL_ERROR "UEFI does not support ARCHITECTURE=${ARCHITECTURE}.")
endif()

# ----------------------------------------------------------------
# Shared UEFI executable
# ----------------------------------------------------------------
set(UEFI_TARGET bootloader_uefi_elf)

add_executable(${UEFI_TARGET}
    common/file_loader.c
)

configure_bootloader_target(${UEFI_TARGET})
target_link_options(${UEFI_TARGET} PRIVATE
    -nostdlib
    -no-pie
    -Wl,--build-id=none
)

# ----------------------------------------------------------------
# Architecture-specific executable setup
# ----------------------------------------------------------------
set(UEFI_APPLICATION_TARGET uefi_application)
set(UEFI_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

add_subdirectory(arch/${ARCHITECTURE})

# ----------------------------------------------------------------
# Find ESP image tools
# ----------------------------------------------------------------
find_program(MKFS_FAT NAMES mkfs.fat mkfs.vfat)
find_program(MMD NAMES mmd)
find_program(MCOPY NAMES mcopy)
find_program(PARTED NAMES parted)
find_program(DD_TOOL NAMES dd REQUIRED)

# ----------------------------------------------------------------
# Export variables
# ----------------------------------------------------------------
set(UEFI_EFI ${CMAKE_CURRENT_BINARY_DIR}/milli.efi)

# ----------------------------------------------------------------
# Convert ELF to EFI
# ----------------------------------------------------------------
add_custom_command(
    OUTPUT ${UEFI_EFI}
    COMMAND ${UEFI_OBJCOPY} -O pei-x86-64 --subsystem 10
            $<TARGET_FILE:${UEFI_TARGET}> ${UEFI_EFI}
    DEPENDS ${UEFI_TARGET}
    VERBATIM
)
