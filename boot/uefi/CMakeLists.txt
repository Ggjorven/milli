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

set(UEFI_ELF_STAMP "${CMAKE_CURRENT_BINARY_DIR}/bootloader_uefi_elf.stamp")
add_custom_command(TARGET ${UEFI_TARGET} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E touch "${UEFI_ELF_STAMP}"
    BYPRODUCTS "${UEFI_ELF_STAMP}"
    VERBATIM
)
set(UEFI_ELF_STAMP "${UEFI_ELF_STAMP}" PARENT_SCOPE)

# ----------------------------------------------------------------
# Shared variables
# ----------------------------------------------------------------
set(UEFI_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
set(UEFI_EFI_FILE "${UEFI_OUTPUT_DIRECTORY}/milli.efi")
set(UEFI_EFI_FILE "${UEFI_EFI_FILE}" PARENT_SCOPE)

# ----------------------------------------------------------------
# Architecture-specific executable setup (+ converts ELF to EFI)
# ----------------------------------------------------------------
add_subdirectory(arch/${ARCHITECTURE})
