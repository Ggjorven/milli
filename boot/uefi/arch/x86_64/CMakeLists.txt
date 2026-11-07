# ----------------------------------------------------------------
# Add x86_64 sources
# ----------------------------------------------------------------
target_sources(${UEFI_TARGET} PRIVATE
    entry.c
)

# ----------------------------------------------------------------
# x86_64 UEFI ABI and linker settings
# ----------------------------------------------------------------
target_compile_options(${UEFI_TARGET} PRIVATE
    -mno-red-zone
    -fshort-wchar
)
target_link_options(${UEFI_TARGET} PRIVATE
    -Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/linker.ld
    -Wl,-e,efi_main
)

# ----------------------------------------------------------------
# Find objcopy for x86_64 which can emit PE
# ----------------------------------------------------------------
# CMAKE_OBJCOPY belongs to the ELF cross toolchain and cannot emit PE/COFF.
find_program(UEFI_OBJCOPY NAMES x86_64-w64-mingw32-objcopy mingw-objcopy REQUIRED)

# ----------------------------------------------------------------
# Convert the ELF executable to an x86_64 UEFI application
# ----------------------------------------------------------------
add_custom_command(
    OUTPUT ${UEFI_EFI_FILE}
    COMMAND ${UEFI_OBJCOPY} -O pei-x86-64 --subsystem 10 $<TARGET_FILE:${UEFI_TARGET}> ${UEFI_EFI_FILE}
    DEPENDS "${UEFI_ELF_STAMP}"
    VERBATIM
)
add_custom_target(bootloader_uefi_efi ALL DEPENDS ${UEFI_EFI_FILE})
add_dependencies(bootloader_uefi_efi ${UEFI_TARGET})

# ----------------------------------------------------------------
# General target
# ----------------------------------------------------------------
add_custom_target(bootloader ALL DEPENDS bootloader_uefi_efi)
