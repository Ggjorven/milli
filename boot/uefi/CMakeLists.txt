# ----------------------------------------------------------------
# Assembly executable (16-bit) (512 bytes)
# ----------------------------------------------------------------
add_executable(bootloader_uefi_x86_64_elf
    common/file_loader.c
    common/memory_map.c
    arch/x86_64/entry.c
    arch/x86_64/paging.c
    $<TARGET_OBJECTS:bootloader_common>
)

configure_bootloader_target(bootloader_uefi_x86_64_elf)
target_compile_options(bootloader_uefi_x86_64_elf PRIVATE
    -mno-red-zone
    -fshort-wchar
)
target_link_options(bootloader_uefi_x86_64_elf PRIVATE
    -nostdlib
    -no-pie
    -Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/arch/x86_64/linker.ld
    -Wl,--build-id=none
    -Wl,-e,efi_main
)

# CMAKE_OBJCOPY belongs to the ELF cross toolchain and usually cannot emit PE.
find_program(UEFI_OBJCOPY NAMES x86_64-w64-mingw32-objcopy mingw-objcopy objcopy REQUIRED)

# UEFI firmware loads a PE/COFF application. Use objcopy to convert from freestanding ELF to PE32+
set(UEFI_APPLICATION ${CMAKE_CURRENT_BINARY_DIR}/BOOTX64.EFI)
add_custom_command(
    OUTPUT ${UEFI_APPLICATION}
    COMMAND ${UEFI_OBJCOPY} -O pei-x86-64 --subsystem 10
            $<TARGET_FILE:bootloader_uefi_x86_64_elf> ${UEFI_APPLICATION}
    DEPENDS bootloader_uefi_x86_64_elf
    VERBATIM
)
add_custom_target(bootloader_uefi_x86_64 DEPENDS ${UEFI_APPLICATION})

# A FAT ESP makes the application directly testable with OVMF/QEMU.
find_program(MKFS_FAT NAMES mkfs.fat mkfs.vfat)
find_program(MMD NAMES mmd)
find_program(MCOPY NAMES mcopy)
find_program(PARTED NAMES parted)
find_program(DD_TOOL NAMES dd REQUIRED)

if(MKFS_FAT AND MMD AND MCOPY AND PARTED)
    set(UEFI_ESP_IMAGE ${CMAKE_CURRENT_BINARY_DIR}/milli-uefi.img)
    set(UEFI_ESP_OFFSET_BYTES 1048576)
    set(UEFI_ESP_OFFSET_SECTORS 2048)
    add_custom_command(
        OUTPUT ${UEFI_ESP_IMAGE}
        COMMAND ${CMAKE_COMMAND} -E rm -f ${UEFI_ESP_IMAGE}
        COMMAND ${DD_TOOL} if=/dev/zero of=${UEFI_ESP_IMAGE} bs=1M count=32
        COMMAND ${PARTED} -s ${UEFI_ESP_IMAGE}
                mklabel gpt mkpart EFI FAT32 1MiB 100% set 1 esp on
        COMMAND ${MKFS_FAT} -F 32 --offset=${UEFI_ESP_OFFSET_SECTORS} ${UEFI_ESP_IMAGE}
        COMMAND ${MMD} -i ${UEFI_ESP_IMAGE}@@${UEFI_ESP_OFFSET_BYTES} ::/EFI ::/EFI/BOOT
        COMMAND ${MCOPY} -i ${UEFI_ESP_IMAGE}@@${UEFI_ESP_OFFSET_BYTES}
                ${UEFI_APPLICATION} ::/EFI/BOOT/BOOTX64.EFI
        DEPENDS ${UEFI_APPLICATION}
        VERBATIM
    )
    add_custom_target(uefi_image DEPENDS ${UEFI_ESP_IMAGE})
    set(MILLI_UEFI_ESP_IMAGE ${UEFI_ESP_IMAGE} CACHE INTERNAL "Path to the generated UEFI ESP image")
else()
    message(STATUS "UEFI ESP image disabled: install dosfstools, mtools, and parted for the uefi_image target")
endif()
