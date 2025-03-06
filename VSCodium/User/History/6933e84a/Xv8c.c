#include <stdio.h>

int main() 
{
    int c, nl, b, t;

    while ((c = getchar()) != EOF) {
        if (c == '\n')
            ++nl;
        printf("%d\n", &nl);
    }
}