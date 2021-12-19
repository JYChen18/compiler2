#include<string.h>
#include<stdio.h>
#include<stdlib.h>
struct RightV{
    char* str;
    int kind; /* 0:symbol , 1:int */
    RightV(char* a, int b){
        str = a;
        kind = b;
    }
};

struct Type{
    char* str;
    RightV* v;
};
#define YYSTYPE Type