%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <map>
#include "head.hpp"
using std::string;
using std::map;

extern FILE* yyin;
extern FILE* yyout;
extern int lineno;

void yyerror(const char *str){
    fprintf(stderr,"Line %d : error %s\n", lineno, str);
}
int yywrap(){
    return 1;
}
int yylex(void);

struct FuncSpace{
    int v_num = 0;              /* global variable num. local stack size. */
    bool root;                  /* global or local. local var is all on stack */
    int param_num;              /* param num */
    int child_param_num = 0;    /* param num for child function */
    char* func_name;            /* func name */
    bool init_flag;             /* need to init after 'var...'! */
    FuncSpace* parent;
    map <string, char*> v_list; /* Eeyore_name -> vi if root==1 else stack_addr/4 */
    map <string, int> v_arr_f;  /* Eeyore_name -> 1 if is array else 0 */
    FuncSpace (bool _root, FuncSpace* _p){
        root = _root;
        if (root) 
            init_flag = 1; 
        else 
            init_flag = 0;
        parent = _p;
    }
};
FuncSpace* global_space = new FuncSpace(1, NULL);
FuncSpace* curr_space = global_space;

struct GlobalInit{
    char* symbol;
    char* int1;
    char* int2;
    GlobalInit* Next;
    GlobalInit (char* _symbol, char* _int1, char* _int2, GlobalInit* _next){
        symbol = _symbol;
        if (_int1 == NULL) 
            int1 = strdup("0");
        else 
            int1 = _int1;
        int2 = _int2;
        Next = _next;
    }
};
GlobalInit* InitHead = NULL;

char* Vint2char(int input){
    char* newchar = new char[4];
    sprintf(newchar,"v%d",input);
    return newchar;
}

char* int2char(int input){
    char* newchar = new char[8];
    sprintf(newchar,"%d",input);
    return newchar;
}

char* Pint2char(int input){
    char* newchar = new char[4];
    sprintf(newchar,"p%d",input);
    return newchar;
}

char* find_symbol(char* symbol){
    string s = symbol; 
    if (curr_space->v_list.find(s) != curr_space->v_list.end())     /* must before global! */
        return curr_space->v_list[s];
    if (global_space->v_list.find(s) != global_space->v_list.end())
        return global_space->v_list[s];
    printf("Undefined variable: %s\n", symbol);
    return symbol;
}

int symbol_is_arr(char* symbol){
    string s = symbol; 
    if (curr_space->v_list.find(s) != curr_space->v_list.end())    /* must before global! */
        return curr_space->v_arr_f[s];
    if (global_space->v_list.find(s) != global_space->v_list.end())
        return global_space->v_arr_f[s];
    return 0;
}

void Symbol_Addr2Reg(char* symbol, int num){
    char* s = find_symbol(symbol);
    if (s[0] == 'p')
        printf("Wrong!!!");
    else
        fprintf(yyout, "loadaddr %s t%d\n", s, num);
}

void RightV2Reg(RightV* v, int num){
    if (v->kind == 1)           
        fprintf(yyout, "t%d = %s\n", num, v->str);
    else if (v->arr_f == 1)
        fprintf(yyout, "loadaddr %s t%d\n", v->str, num);
    else
        fprintf(yyout, "load %s t%d\n", v->str, num);
}

void FuncInit(){
    if (curr_space->init_flag == 0){
        fprintf(yyout, "%s [%d] [%d]\n", curr_space->func_name, curr_space->param_num, curr_space->param_num+curr_space->v_num);
        for (int i=0; i < curr_space->param_num; i++){
            fprintf(yyout, "store a%d %d\n", i, curr_space->v_num);
            curr_space->v_list[Pint2char(i)] = int2char(curr_space->v_num);
            curr_space->v_num += 1;
        }
        curr_space->init_flag = 1;
    }
    if (strcmp(curr_space->func_name, "f_main")==0){
        while (InitHead != NULL){
            Symbol_Addr2Reg(InitHead->symbol, 0);
            fprintf(yyout, "t1 = %s\n", InitHead->int2);
            fprintf(yyout, "t0[%s] = t1\n", InitHead->int1);
            InitHead = InitHead->Next;
        }
    }
}

%}
%token<str> COL LBRK RBRK IF GOTO RETURN CALL PARAM END
%token<str> OP LABEL FUNC VAR ENTER ASSIGN SYMBOL INT
%type<v> RightValue
%%

Program : Program Declaration 
        | Program Initialization 
        | Program FunctionDef 
        | Program ENTER 
        | {}
        ;
Declaration:
    VAR INT SYMBOL
    {
        if (curr_space->root){
            fprintf(yyout, "v%d = malloc %s\n", curr_space->v_num, $2);
            curr_space->v_list[$3] = Vint2char(curr_space->v_num);
            curr_space->v_num += 1;
        }
        else{
            curr_space->v_list[$3] = int2char(curr_space->v_num);
            curr_space->v_num += atoi($2) / 4;
        }
        curr_space->v_arr_f[$3] = 1;
    }
    | VAR SYMBOL
    {
        if (curr_space->root){
            fprintf(yyout, "v%d = 0\n", curr_space->v_num);
            curr_space->v_list[$2] = Vint2char(curr_space->v_num);
        }
        else{
            curr_space->v_list[$2] = int2char(curr_space->v_num);
        }
        curr_space->v_arr_f[$2] = 0;
        curr_space->v_num += 1;
    }
    ;
Initialization:
    SYMBOL ASSIGN INT{
        GlobalInit* elem = new GlobalInit($1, NULL, $3, InitHead);
        InitHead = elem;
    }
    | SYMBOL LBRK INT RBRK ASSIGN INT{
        GlobalInit* elem = new GlobalInit($1, $3, $6, InitHead);
        InitHead = elem;
    }

FunctionDef:
    FunctionHeader Statements FunctionEnd {}
    ;

Statements:
    Statements Statement
    | Statements ENTER
    | {}
    ;

FunctionHeader:
    FUNC LBRK INT RBRK
    {
        FuncSpace * new_space = new FuncSpace(0, curr_space);
        curr_space = new_space;
        curr_space->func_name = $1;
        curr_space->param_num = atoi($3);
    }
    ;

FunctionEnd:
    END FUNC
    {
        curr_space = curr_space->parent;
        curr_space->child_param_num = 0;
        fprintf(yyout, "end %s\n", $2);
    }
    ;

Statement:
    Expression
    | Declaration 
    ;

Expression:
    SYMBOL ASSIGN RightValue OP RightValue ENTER
    {
        FuncInit();
        Symbol_Addr2Reg($1, 0);
        RightV2Reg($3, 1);
        RightV2Reg($5, 2);
        fprintf(yyout, "t3 = t1 %s t2\n", $4);
        fprintf(yyout, "t0[0] = t3\n");
    }
    | SYMBOL ASSIGN OP RightValue ENTER
    {
        FuncInit();
        Symbol_Addr2Reg($1, 0);
        RightV2Reg($4, 1);
        fprintf(yyout, "t2 = %s t1\n", $3);
        fprintf(yyout, "t0[0] = t2\n");
    }
    | SYMBOL ASSIGN RightValue ENTER
    {
        FuncInit();
        Symbol_Addr2Reg($1, 0);
        RightV2Reg($3, 1);
        fprintf(yyout, "t0[0] = t1\n");
    }
    | SYMBOL LBRK RightValue RBRK ASSIGN RightValue ENTER
    {
        FuncInit();
        Symbol_Addr2Reg($1, 0);
        RightV2Reg($3, 1);
        RightV2Reg($6, 2);
        fprintf(yyout, "t0 = t0 + t1\n");
        fprintf(yyout, "t0[0] = t2\n");
    }
    | SYMBOL ASSIGN RightValue LBRK RightValue RBRK ENTER
    {
        FuncInit();
        Symbol_Addr2Reg($1, 0);
        RightV2Reg($3, 1);
        RightV2Reg($5, 2);
        fprintf(yyout, "t1 = t1 + t2\n");
        fprintf(yyout, "t3 = t1[0]\n");
        fprintf(yyout, "t0[0] = t3\n");

    }
    | IF RightValue OP RightValue GOTO LABEL 
    {
        FuncInit();
        RightV2Reg($2, 0);
        RightV2Reg($4, 1);
        fprintf(yyout, "if t0 %s t1 goto %s\n", $3, $6);
    }
    | GOTO LABEL
    {
        FuncInit();
        fprintf(yyout, "goto %s\n", $2);
    }
    | LABEL COL
    {
        FuncInit();
        fprintf(yyout, "%s:\n", $1);
    }
    | PARAM RightValue
    {
        FuncInit();
        RightV2Reg($2, 0);
        fprintf(yyout, "a%d = t0\n", curr_space->child_param_num);
        curr_space->child_param_num += 1;
    }
    | CALL FUNC
    {
        FuncInit();
        fprintf(yyout, "call %s\n", $2);
    }
    | SYMBOL ASSIGN CALL FUNC
    {
        FuncInit();
        fprintf(yyout, "call %s\n", $4);
        Symbol_Addr2Reg($1, 0);
        fprintf(yyout, "t0[0] = a0\n");
    }
    | RETURN RightValue
    {
        FuncInit();
        RightV2Reg($2, 0);
        fprintf(yyout, "a0 = t0\n");
        fprintf(yyout, "return\n");
    }
    | RETURN ENTER
    {
        FuncInit();
        fprintf(yyout, "return\n");
    }

RightValue:
    SYMBOL {$$ = new RightV(find_symbol($1), 0, symbol_is_arr($1));}
    | INT  {$$ = new RightV($1, 1, 0);}
    ;
%%
