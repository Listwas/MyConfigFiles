#include <stdio.h>

int main() 
{
    float celcius, fahr;
    int step, lower, upper; 

    lower = 0;
    upper = 30;
    step = 20;
    celcius = lower;

    while (celcius <= upper) {
        fahr = (5/9) * (fahr - 32);
        printf("%3.0f %6.1f", fahr, celcius);
        celcius += step;
    }
}