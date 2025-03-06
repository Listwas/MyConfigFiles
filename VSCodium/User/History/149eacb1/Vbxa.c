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
            // printf("l=%d\nw=%d\nh=%d\n", l, w, h);
            int x = l * h;
            int y = w * h;
            int z = l * w;

            int smallest, second_smallest;
            smallest_num(x, y, z, &smallest, &second_smallest);

            int box_volume = l * w * h;            
            int bracket = 2 * (x + y + z) + smallest;  
            int perimeter = 2 * (smallest + second_smallest);

            int feet_of_ribbon = perimeter + box_volume;

            ribbon += feet_of_ribbon;
            sum += bracket;
            ptr += consumed;
    }
    printf("total square feet of wrapping paper: %d\n", total_paper);
    printf("total feet of ribbon to order: %d\n", total_ribbon);
}