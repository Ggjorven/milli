if(NOT DEFINED INPUT_FILE OR NOT DEFINED SECTOR_SIZE_BYTES OR NOT DEFINED MAX_SECTORS)
    message(FATAL_ERROR
        "INPUT_FILE, SECTOR_SIZE_BYTES, and MAX_SECTORS are required to check the BIOS stage-2 size.")
endif()

file(SIZE "${INPUT_FILE}" STAGE2_SIZE_BYTES)
math(EXPR MAX_STAGE2_SIZE_BYTES "${SECTOR_SIZE_BYTES} * ${MAX_SECTORS}")

if(STAGE2_SIZE_BYTES GREATER MAX_STAGE2_SIZE_BYTES)
    message(FATAL_ERROR
        "BIOS stage 2 (${STAGE2_SIZE_BYTES} bytes) exceeds its reserved area "
        "(${MAX_SECTORS} sectors, ${MAX_STAGE2_SIZE_BYTES} bytes). "
        "Writing it would overwrite the FAT32 partition.")
endif()
