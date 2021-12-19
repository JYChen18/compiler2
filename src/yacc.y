%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <map>
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

struct RightV{
    char* str;
    int kind; /* 0:symbol , 1:int */
    RightV(char* a, int b){
        str = a;
        kind = b;
    }
};

struct FuncSpace{
    int v_num = 0;          /* variable num */
    int param_num = 0;      /* param num */
    int stack_start;        /* stack starting address/4 */
    bool root;              /* global var is on heap?, local var is on stack */
    FuncSpace* parent;
    map <char*, char*> v_list;  /* Eeyore_name -> vi if root==1 else stack_addr/4 */

    FuncSpace (bool _root, int _start, FuncSpace* _p){
        root = _root;
        stack_start = _start;
        parent = _p;
    }
};
FuncSpace* global_space = new FuncSpace(1, 0, NULL);
FuncSpace* curr_space = global_space;

char* global_char;
char* int2char(int input){
    /* change int to char* */
    sprintf(global_char,"%d",input);
    return global_char;
}
char* Vint2char(int input){
    sprintf(global_char,"v%d",input);
    return global_char;
}

char* find_symbol(char* symbol){
    if (global_space->v_list.find(symbol) != global_space->v_list.end())
        return global_space->v_list[symbol];
    if (curr_space->v_list.find(symbol) != curr_space->v_list.end())
        return curr_space->v_list[symbol];
    printf("Undefined variable!\n");
    return NULL;
}

void Symbol2Reg(char* s, int num){
    fprintf(yyout, "loadaddr %s t%d\n", find_symbol(s), num);
}

void RightV2Reg(RightV* v, int num){
    if (v->kind == 0){
        fprintf(yyout, "load %s t%d\n", v->str, num);
    }
    else{
        fprintf(yyout, "t%d = %s\n", num, v->str);
    }
}

struct Type{
    char* str;
    RightV* v;
};
#define YYSTYPE Type

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
        }
        else{
            curr_space->v_list[$3] = int2char(curr_space->v_num + curr_space->stack_start);
        }
        curr_space->v_num += 1;
    }
    | VAR SYMBOL
    {
        if (curr_space->root){
            fprintf(yyout, "v%d = 0\n", curr_space->v_num);
            curr_space->v_list[$2] = Vint2char(curr_space->v_num);
        }
        else{
            curr_space->v_list[$2] = int2char(curr_space->v_num + curr_space->stack_start);
        }
        curr_space->v_num += 1;
    }
    ;
Initialization:
    SYMBOL ASSIGN INT{
        fprintf(yyout, "%s = %s\n", find_symbol($1), $3);
    }
    | SYMBOL LBRK INT RBRK ASSIGN INT{
        Symbol2Reg($1, 0);
        fprintf(yyout, "t1 = %s\n", $3);
        fprintf(yyout, "t0 = t0 + t1\n");
        fprintf(yyout, "t0[0] = %s\n", $6);
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
        FuncSpace * new_space;
        if (curr_space->root)
            new_space = new FuncSpace(0, 0, curr_space);
        else
            new_space = new FuncSpace(0, curr_space->v_num, curr_space);
        curr_space = new_space;
            fprintf(yyout, "%s [%s] [%d]\n", $1, $3, 5); /* buggy? 5 is enough? */
    }
    ;

FunctionEnd:
    END FUNC
    {
        curr_space = curr_space->parent;
            fprintf(yyout, "end %s\n", $2);
    }
    ;

Statement:
    Expression
    | Declaration
    ;

Expression:
    SYMBOL ASSIGN RightValue OP RightValue
    {
        Symbol2Reg($1, 0);
        RightV2Reg($3, 1);
        RightV2Reg($5, 2);
        fprintf(yyout, "t3 = t1 %s t2\n", $4);
        fprintf(yyout, "t0[0] = t3\n");
    }
    | SYMBOL ASSIGN OP RightValue
    {
        Symbol2Reg($1, 0);
        RightV2Reg($4, 1);
        fprintf(yyout, "t2 = %s t1\n", $3);
        fprintf(yyout, "t0[0] = t2\n");
    }
    | SYMBOL ASSIGN RightValue
    {
        Symbol2Reg($1, 0);
        RightV2Reg($3, 1);
        fprintf(yyout, "t0[0] = t1\n");
    }
    | SYMBOL LBRK RightValue RBRK ASSIGN RightValue
    {
        Symbol2Reg($1, 0);
        RightV2Reg($3, 1);
        RightV2Reg($6, 2);
        fprintf(yyout, "t0 = t0 + t1\n");
        fprintf(yyout, "t0[0] = t2\n");
    }
    | SYMBOL ASSIGN SYMBOL LBRK RightValue RBRK
    {
        Symbol2Reg($1, 0);
        Symbol2Reg($3, 1);
        RightV2Reg($5, 2);
        fprintf(yyout, "t1 = t1 + t2\n");
        fprintf(yyout, "t3 = t1[0]\n");
        fprintf(yyout, "t0[0] = t3\n");

    }
    | IF RightValue OP RightValue GOTO LABEL
    {
        RightV2Reg($2, 0);
        RightV2Reg($4, 1);
        fprintf(yyout, "if t0 %s t1 goto %s\n", $3, $6);
    }
    | GOTO LABEL
    {
        fprintf(yyout, "\tgoto %s\n", $2);
    }
    | LABEL COL
    {
        fprintf(yyout, "%s:\n", $1);
    }
    | PARAM RightValue
    {
        fprintf(yyout, "a%d = %s\n", curr_space->param_num, $2->str);
        curr_space->param_num += 1;
    }
    | CALL FUNC
    {
        fprintf(yyout, "\tcall %s\n", $2);
    }
    | SYMBOL ASSIGN CALL FUNC
    {
        fprintf(yyout, "\tcall %s\n", $4);
        fprintf(yyout, "\tloadaddr %s t0\n", find_symbol($1));
        fprintf(yyout, "\tt0[0] = a0\n");
    }
    | RETURN RightValue
    {
        fprintf(yyout, "\ta0 = %s\n", $2->str);
        fprintf(yyout, "\treturn\n");
    }
    | RETURN
    {
        fprintf(yyout, "\treturn\n");
    }

RightValue:
    SYMBOL {$$ = new RightV(find_symbol($1), 0);}
    | INT  {$$ = new RightV($1, 1);}
    ;
%%