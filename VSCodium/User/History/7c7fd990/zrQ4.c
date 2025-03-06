#include <stdio.h>

struct pos {
    int x;
    int y;
    int visited;
};

int main() {
    FILE *f = fopen("input.txt", "r");

    if (!f) {
        perror("file error: open\n");
        return 1;
    }
    
    fseek(f, 0L, SEEK_END);
    int f_length = ftell(f);
    fseek(f, 0L, SEEK_SET);

    char f_content[f_length + 1];
    f_content[f_length] = 0;
    fread(f_content, 1, f_length, f);


    struct pos x_axis;
    struct pos y_axis;
    char positions[12][12];
    for (int i; i <= f_length; i++) {
        if (f_content[i] == '^') {
            x_axis.x++;
        } else if (f_content[i] == 'v') {
            x_axis.x--;
        } else if (f_content[i] == '>') {
            y_axis.y++;
        } else if (f_content[i] == '<') {
            y_axis.y--;
        }
        positions[x_axis.x][y_axis.y];

    }
    fclose(f);
    printf("%s", positions[1][1] );
    printf("x:%d y:%d\n", x_axis.x, y_axis.y);
}