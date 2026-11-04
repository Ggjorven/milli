# This file is included only when BOOTLOADER is set to "limine".

set(LIMINE_BRANCH "v11.x-binary" CACHE STRING "Limine binary-release branch/tag to fetch")
set(LIMINE_DIR "" CACHE PATH "Existing Limine binary checkout (empty = fetch it)")

if(NOT LIMINE_DIR)
    include(FetchContent)
    FetchContent_Declare(limine
        GIT_REPOSITORY https://github.com/limine-bootloader/limine.git
        GIT_TAG        ${LIMINE_BRANCH}
        GIT_SHALLOW    TRUE
        SOURCE_SUBDIR  _no_cmake_here
    )
    FetchContent_MakeAvailable(limine)
    set(LIMINE_DIR ${limine_SOURCE_DIR})
endif()

find_program(MAKE_TOOL NAMES make gmake)
if(NOT EXISTS ${LIMINE_DIR}/limine AND EXISTS ${LIMINE_DIR}/Makefile AND MAKE_TOOL)
    execute_process(COMMAND ${MAKE_TOOL} -C ${LIMINE_DIR} RESULT_VARIABLE _exit_code)
    if(NOT _exit_code EQUAL 0)
        message(WARNING "Building the limine tool failed; the 'iso' target won't work")
    endif()
endif()
