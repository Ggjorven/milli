add_library(bootloader_common OBJECT
    common/config.cpp
    common/elf_loader.cpp
    common/handoff.cpp
)

function(configure_bootloader_target target)
    target_compile_features(${target} PRIVATE cxx_std_20)
    target_include_directories(${target} PRIVATE ${PROJECT_SOURCE_DIR})
    target_compile_options(${target} PRIVATE
        $<$<COMPILE_LANGUAGE:C,CXX>:-ffreestanding>
        $<$<COMPILE_LANGUAGE:C,CXX>:-fno-exceptions>
        $<$<COMPILE_LANGUAGE:C,CXX>:-fno-rtti>
        $<$<COMPILE_LANGUAGE:C,CXX>:-fno-stack-protector>
        $<$<COMPILE_LANGUAGE:C,CXX>:-fno-pie>
    )
endfunction()

configure_bootloader_target(bootloader_common)

add_subdirectory(bios)
add_subdirectory(limine)
add_subdirectory(uefi)

add_custom_target(bootloader DEPENDS
    bootloader_bios_x86
    bootloader_limine_x86_64
    bootloader_uefi_x86_64
)
