# ----------------------------------------------------------------
# Add x86_64 sources
# ----------------------------------------------------------------
target_sources(${UEFI_TARGET} PRIVATE
    entry.c
    paging.c
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
# Convert the ELF executable to an x86_64 UEFI application
# ----------------------------------------------------------------
# CMAKE_OBJCOPY belongs to the ELF cross toolchain and usually cannot emit PE.
find_program(UEFI_OBJCOPY NAMES x86_64-w64-mingw32-objcopy mingw-objcopy objcopy REQUIRED)

# UEFI removable-media boot path for x86_64: EFI/BOOT/BOOTX64.EFI.
set(UEFI_BOOT_PATH EFI/BOOT/BOOTX64.EFI)
set(UEFI_APPLICATION ${UEFI_OUTPUT_DIRECTORY}/BOOTX64.EFI)
add_custom_command(
    OUTPUT ${UEFI_APPLICATION}
    COMMAND ${UEFI_OBJCOPY} -O pei-x86-64 --subsystem 10
            $<TARGET_FILE:${UEFI_TARGET}> ${UEFI_APPLICATION}
    DEPENDS ${UEFI_TARGET}
    VERBATIM
)
add_custom_target(${UEFI_APPLICATION_TARGET} DEPENDS ${UEFI_APPLICATION})

add_custom_target(bootloader_uefi_x86_64 DEPENDS ${UEFI_APPLICATION_TARGET})

set(UEFI_APPLICATION ${UEFI_APPLICATION} PARENT_SCOPE)
set(UEFI_BOOT_PATH ${UEFI_BOOT_PATH} PARENT_SCOPE)
