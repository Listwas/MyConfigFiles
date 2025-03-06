#include <stdio.h>

void find_two_smallest(int a, int b, int c, int *smallest, int *second_smallest) {
    if (a <= b && a <= c) {
        *smallest = a;
        *second_smallest = (b <= c) ? b : c;
    } 
    else if (b <= a && b <= c) {
        *smallest = b;
        *second_smallest = (a <= c) ? a : c;
    }
    else {
        *smallest = c;
        *second_smallest = (a <= b) ? a : b;
    }
}

int main() {
    FILE *f = fopen("input", "r");
    if (!f) {
        perror("file error: open\n");
        return 1;
    }

    int l, w, h;
    int total_paper = 0;
    int total_ribbon = 0;

    while (fscanf(f, "%dx%dx%d", &l, &w, &h) == 3) {
        // Wrapping paper calculations
        int area1 = l * w;
        int area2 = w * h;
        int area3 = h * l;

        int surface_area = 2 * (area1 + area2 + area3);
    }