#include <stio.h>

int main() 
{
    int c;

    while ((c = getchar() != EOF))
        putchar(c);
}