# Legacy BIOS is x86 only

# ----------------------------------------------------------------
# Assembly executable (16-bit) (512 bytes)
# ----------------------------------------------------------------
add_executable(bootloader_bios_stage1_elf
    stage1.S
    realmode.S
)
target_compile_options(bootloader_bios_stage1_elf PRIVATE -m16 -m32)
target_link_options(bootloader_bios_stage1_elf PRIVATE
    -m32 -nostdlib -no-pie
    -Wl,-m,elf_i386
    -Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/stage1.ld
    -Wl,--build-id=none
)

# ----------------------------------------------------------------
# C executable (64-bit)
# ----------------------------------------------------------------
add_executable(bootloader_bios_stage2_elf
    transition.S
    stage2.c
)
configure_bootloader_target(bootloader_bios_stage2_elf)
target_compile_options(bootloader_bios_stage2_elf PRIVATE
    $<$<COMPILE_LANGUAGE:C,ASM>:-m32>
)
target_link_options(bootloader_bios_stage2_elf PRIVATE
    -m32 -nostdlib -no-pie
    -Wl,-m,elf_i386
    -Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/stage2.ld
    -Wl,--build-id=none
)

# ----------------------------------------------------------------
# Export variables
# ----------------------------------------------------------------
set(BIOS_STAGE1_BIN ${CMAKE_CURRENT_BINARY_DIR}/stage1.bin)
set(BIOS_STAGE2_BIN ${CMAKE_CURRENT_BINARY_DIR}/stage2.bin)
set(BIOS_IMAGE ${CMAKE_CURRENT_BINARY_DIR}/milli-bios.img)

# ----------------------------------------------------------------
# Convert ELF files to BIN files (strips ELF metadata)
# ----------------------------------------------------------------
add_custom_command(
    OUTPUT ${BIOS_STAGE1_BIN}
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:bootloader_bios_stage1> ${BIOS_STAGE1_BIN}
    DEPENDS bootloader_bios_stage1_elf
    VERBATIM
)
add_custom_command(
    OUTPUT ${BIOS_STAGE2_BIN}
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:bootloader_bios_stage2> ${BIOS_STAGE2_BIN}
    DEPENDS bootloader_bios_stage2_elf
    VERBATIM
)

# ----------------------------------------------------------------
# Find dd
# ----------------------------------------------------------------
find_program(DD_TOOL NAMES dd REQUIRED)

# ----------------------------------------------------------------
# Create the image target
# ----------------------------------------------------------------
add_custom_command(
    OUTPUT ${BIOS_IMAGE}
    COMMAND ${CMAKE_COMMAND} -E copy ${BIOS_STAGE1_BIN} ${BIOS_IMAGE} # Create the .img from the first bin
    COMMAND ${DD_TOOL} if=${BIOS_STAGE2_BIN} of=${BIOS_IMAGE} bs=1 seek=512 conv=notrunc # Append the second bin onto it after the first 512 bytes
    DEPENDS ${BIOS_STAGE1_BIN} ${BIOS_STAGE2_BIN}
    VERBATIM
)

add_custom_target(bootloader DEPENDS ${BIOS_IMAGE})

# ----------------------------------------------------------------
# Create the run targets
# ----------------------------------------------------------------
set(QEMU_COMMON_ARGS -M q35 -m 512M -serial stdio -no-reboot -no-shutdown)

add_custom_target(run
    COMMAND ${QEMU} ${QEMU_COMMON_ARGS} -drive format=raw,file=${BIOS_IMAGE}
    DEPENDS bootloader
    USES_TERMINAL)
add_custom_target(run-debug
    COMMAND ${QEMU} ${QEMU_COMMON_ARGS} -drive format=raw,file=${BIOS_IMAGE} -s -S
    DEPENDS bootloader
    USES_TERMINAL)
