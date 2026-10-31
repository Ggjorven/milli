namespace boot::limine::x86_64
{

    using KernelEntry = void (*)();

    [[maybe_unused]] [[noreturn]] void handoff_to_kernel(KernelEntry kernel_entry)
    {
        kernel_entry();

        for (;;)
        {
            asm volatile("hlt");
        }
    }

}
