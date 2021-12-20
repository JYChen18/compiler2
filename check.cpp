#include <iostream>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <map>
using std:: map;

int main(){
    int x = 10;
    int y = atoi("100");
    char* Pint2char(int input){
    char* newchar = new char[4];
    sprintf(newchar,"p%d",input);
    return newchar;
    }
    printf("%s\n", Pint2char(0));
}
