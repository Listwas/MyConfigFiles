#include <stdio.h>

int main() 
{
    int c;

    while ((c = getchar()) != EOF) {
        if (EOF == 1) {
            printf("eof == 1");
        }
        printf("%d", EOF);
        putchar(c);
    }
}