#include <stdio.h>

int find_two_smallest(int a, int b, int c, int *smallest, int *second_smallest) {
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

    while (fscanf(f, "%dx%dx%d%n", &l, &w, &h, &consumed) == 3) {
            int area1 = l * h;
            int area2 = w * h;
            int area3 = l * w;

            int surface_area = 2 * (area1 + area2 + area3);
            int smallest_area = find_two_smallest(area1, area2, area3);
    }
    printf("total square feet of wrapping paper: %d\n", total_paper);
    printf("total feet of ribbon to order: %d\n", total_ribbon);
}