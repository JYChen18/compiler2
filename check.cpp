#include <iostream>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <map>
using std:: map;
int main(){
    int x = 10;
    char* y = strdup("T0");
    if (y[0] == 'T'){
        y[0] = 'a';
    }
    printf("%s\n", y);
}
