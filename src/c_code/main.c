#include <stdio.h>
#include <stdlib.h>

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

void printn(int n)
{

    char c[50];
    itoa(n, c, 10);
    prints(c);
    prints("\n");
}


int main()
{
    prints("\n\n\n\n");
    prints("Hello QuantaRV!\n");
    printn(10+23);
    printn(10-23);
    printn(10*23);
    printn((10*23)/10);
    printn(10*230);
    while (1); 
}