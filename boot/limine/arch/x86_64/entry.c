typedef void (*KernelEntry)(void);

__attribute__((unused, noreturn)) void handoff_to_kernel(KernelEntry kernel_entry)
    {
        kernel_entry();

        for (;;)
        {
            __asm__ __volatile__("hlt");
        }
    }

