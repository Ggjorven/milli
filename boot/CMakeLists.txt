add_library(bootloader_common OBJECT
    common/config.c
    common/elf_loader.c
    common/handoff.c
)

function(configure_bootloader_target target)
    target_compile_features(${target} PRIVATE c_std_23)
    target_include_directories(${target} PRIVATE ${PROJECT_SOURCE_DIR})
    target_compile_options(${target} PRIVATE
        $<$<COMPILE_LANGUAGE:C>:-ffreestanding>
        $<$<COMPILE_LANGUAGE:C>:-fno-stack-protector>
        $<$<COMPILE_LANGUAGE:C>:-fno-pie>
    )
endfunction()

configure_bootloader_target(bootloader_common)

add_subdirectory(bios)
add_subdirectory(limine)
add_subdirectory(uefi)

if(BOOTLOADER STREQUAL "bios")
    add_custom_target(bootloader DEPENDS bootloader_bios_x86)
elseif(BOOTLOADER STREQUAL "limine")
    add_custom_target(bootloader DEPENDS bootloader_limine_x86_64)
elseif(BOOTLOADER STREQUAL "uefi")
    add_custom_target(bootloader DEPENDS bootloader_uefi_x86_64)
endif()
