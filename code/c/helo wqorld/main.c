#include <stdio.h>
#include <stdlib.h>
#define clrscr() printf("\e[1;1H\e[2J")

int main(int argc, char **argv) { 
    char sex;
    float gender;

    int beer_count;
    float ml;

    float volts;
    float calc_volts;
    float constant = 0.789 ;

    float mg;
    float body_mass;
    float m_times_r;
    float BAC;

	if (argv[1][0] == 'm')
            gender = 0.68;
	if (argv[1][0] == 'w')
            gender = 0.55;

    printf("how much beers u drank tonight???\n");
	beer_count = strtol(argv[2], NULL, 10);

    printf("give me Volts of your holy gral(beer)\n");
	volts = strtof(argv[3], NULL);

    printf("how fat are you???\n");
    body_mass = strtof(argv[4], NULL);

    ml = beer_count * 500;
    calc_volts = volts / 100;

    mg = ml * calc_volts * constant;
    m_times_r = body_mass * gender;
    
    BAC = mg / m_times_r;
    
    printf("you are %0.2f %s", BAC, "promille in \n");
}
