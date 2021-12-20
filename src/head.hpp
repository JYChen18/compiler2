#include<string.h>
#include<stdio.h>
#include<stdlib.h>
struct RightV{
    char* str;
    int kind;   /* 0:symbol , 1:int */
    int arr_f;  /* array or not */
    RightV(char* _str, int _kind, int _arr_f){
        str = _str;
        kind = _kind;
        arr_f = _arr_f;
    }
};

struct Type{
    char* str;
    RightV* v;
};
#define YYSTYPE Type