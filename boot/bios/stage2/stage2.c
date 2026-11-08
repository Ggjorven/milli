__attribute__((noreturn)) void stage2_main(void)
{
    for (;;)
    {
        __asm__ __volatile__("hlt");
    }
}
