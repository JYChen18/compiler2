#include <iostream>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <map>
using std:: map;
int main(){
    int x = 10;
    char* y = "T0";
    char* z = "T1";

    struct FuncSpace{
        int v_num = 0;
        bool root;
        FuncSpace* parent;
        map <char*, int> v_list; 
        map <char*, bool> v_array_flag;

        FuncSpace (bool _root, FuncSpace* _p){
            root = _root;
            parent = _p;
        }
    };
    FuncSpace* global_space = new FuncSpace(1, NULL);
    global_space->v_list[y] = global_space->v_num;
    global_space->v_num ++;
    global_space->v_list[z] = global_space->v_num;
    global_space->v_num ++;
    FuncSpace* curr_space = global_space;

    FuncSpace* new_space = new FuncSpace(0, curr_space);
    curr_space = new_space;
    printf("%d", curr_space->root);
    curr_space = curr_space->parent;
    printf("%d", curr_space->root);
    printf("%d", curr_space->v_list["TX"]);
}
