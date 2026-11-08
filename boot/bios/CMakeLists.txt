# Legacy BIOS is x86 architectures only

# ----------------------------------------------------------------
# Assembly executable (16-bit) (512 bytes)
# ----------------------------------------------------------------
add_executable(bootloader_bios_stage1_elf
    stage1/stage1.S
    stage1/realmode.S
)
target_compile_options(bootloader_bios_stage1_elf PRIVATE -m16 -m32)
target_link_options(bootloader_bios_stage1_elf PRIVATE
    -m32 -nostdlib -no-pie
    -Wl,-m,elf_i386
    -Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/stage1/stage1.ld
    -Wl,--build-id=none
)

# ----------------------------------------------------------------
# C executable (64-bit)
# ----------------------------------------------------------------
add_executable(bootloader_bios_stage2_elf
    stage2/transition.S
    stage2/stage2.c
)
configure_bootloader_target(bootloader_bios_stage2_elf)
target_compile_options(bootloader_bios_stage2_elf PRIVATE
    $<$<COMPILE_LANGUAGE:C,ASM>:-m32>
)
target_link_options(bootloader_bios_stage2_elf PRIVATE
    -m32 -nostdlib -no-pie
    -Wl,-m,elf_i386
    -Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/stage2/stage2.ld
    -Wl,--build-id=none
)

# ----------------------------------------------------------------
# Export variables
# ----------------------------------------------------------------
set(BIOS_STAGE1_BIN "${CMAKE_CURRENT_BINARY_DIR}/stage1.bin")
set(BIOS_STAGE2_BIN "${CMAKE_CURRENT_BINARY_DIR}/stage2.bin")
set(BIOS_STAGE1_BIN "${BIOS_STAGE1_BIN}" PARENT_SCOPE)
set(BIOS_STAGE2_BIN "${BIOS_STAGE2_BIN}" PARENT_SCOPE)

# ----------------------------------------------------------------
# Convert ELF files to BIN files (strips ELF metadata)
# ----------------------------------------------------------------
add_custom_command(
    OUTPUT ${BIOS_STAGE1_BIN}
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:bootloader_bios_stage1_elf> ${BIOS_STAGE1_BIN}
    DEPENDS bootloader_bios_stage1_elf
    VERBATIM
)
add_custom_target(bootloader_bios_stage1_bin ALL DEPENDS ${BIOS_STAGE1_BIN})

add_custom_command(
    OUTPUT ${BIOS_STAGE2_BIN}
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:bootloader_bios_stage2_elf> ${BIOS_STAGE2_BIN}
    DEPENDS bootloader_bios_stage2_elf
    VERBATIM
)
add_custom_target(bootloader_bios_stage2_bin ALL DEPENDS ${BIOS_STAGE2_BIN})

# ----------------------------------------------------------------
# General target
# ----------------------------------------------------------------
add_custom_target(bootloader ALL DEPENDS bootloader_bios_stage1_bin bootloader_bios_stage2_bin)
