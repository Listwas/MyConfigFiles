#include <stdio.h>

int main() 
{
    int c;

    while ((c = getchar()) != EOF) {
        if (EOF == 1) {
            printf("eof == 1");
        }
        else{
            printf("%d", EOF);
            putchar(c);
        }
        
    }
}