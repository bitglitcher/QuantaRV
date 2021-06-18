

void prints(char* string)
{
    char* c = string;
    volatile char* d = (char*)0xffff;  
    while(*c)
    {
        *d = *c;
        c++;
    }
}


int main()
{
    prints("Hello QuantaRV!\n");
}