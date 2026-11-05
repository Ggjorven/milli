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
# Shared variables
# ----------------------------------------------------------------
set(UEFI_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
set(UEFI_EFI_FILE ${UEFI_OUTPUT_DIRECTORY}/milli.efi PARENT_SCOPE)

# ----------------------------------------------------------------
# Architecture-specific executable setup (+ converts ELF to EFI)
# ----------------------------------------------------------------
add_subdirectory(arch/${ARCHITECTURE})
