# Legacy BIOS has only an x86 entry environment. stage1 and realmode begin in 16-bit real mode.
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

# Transition makes it 64-bit
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

set(BIOS_STAGE1_BIN ${CMAKE_CURRENT_BINARY_DIR}/stage1.bin)
set(BIOS_STAGE2_BIN ${CMAKE_CURRENT_BINARY_DIR}/stage2.bin)
set(BIOS_IMAGE ${CMAKE_CURRENT_BINARY_DIR}/milli-bios.img)

add_custom_command(
    OUTPUT ${BIOS_STAGE1_BIN}
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:bootloader_bios_stage1_elf> ${BIOS_STAGE1_BIN}
    DEPENDS bootloader_bios_stage1_elf
    VERBATIM
)
add_custom_command(
    OUTPUT ${BIOS_STAGE2_BIN}
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:bootloader_bios_stage2_elf> ${BIOS_STAGE2_BIN}
    DEPENDS bootloader_bios_stage2_elf
    VERBATIM
)

find_program(DD_TOOL NAMES dd REQUIRED)
add_custom_command(
    OUTPUT ${BIOS_IMAGE}
    COMMAND ${CMAKE_COMMAND} -E copy ${BIOS_STAGE1_BIN} ${BIOS_IMAGE}
    COMMAND ${DD_TOOL} if=${BIOS_STAGE2_BIN} of=${BIOS_IMAGE} bs=1 seek=512 conv=notrunc
    DEPENDS ${BIOS_STAGE1_BIN} ${BIOS_STAGE2_BIN}
    VERBATIM
)

add_custom_target(bios_image DEPENDS ${BIOS_IMAGE})
add_custom_target(bootloader_bios_x86 DEPENDS bios_image)

set(MILLI_BIOS_IMAGE ${BIOS_IMAGE} CACHE INTERNAL "Path to the generated BIOS disk image")
