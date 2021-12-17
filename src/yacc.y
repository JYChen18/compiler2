%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern FILE* yyin;
extern FILE* yyout;
extern int lineno;

void yyerror(const char *str){
    fprintf(stderr,"Line %d : error %s\n", lineno, str);
    //exit(1);
}

int yywrap(){
    return 1;
}
int yylex(void);
int STK = 0;
%}

%union {
    int num;
    char* str;
};

%token<str> COL LBRK RBRK IF GOTO RETURN CALL STORE LOAD LOADARRD MALLOC END
%token<str> OP LABEL FUNC REG VAR ENTER ASSIGN
%token<num> INT

%%

Program : Program FUNCFunctionDef  {}
        | Program GlobalVarDecl  {}
        | Program ENTER {}
        | {}
        ;
GlobalVarDecl:
    VAR ASSIGN INT ENTER
    {
        fprintf(yyout, "\t.global %s\n", $1);
        fprintf(yyout, "\t.section .sdata\n");
        fprintf(yyout, "\t.align 2\n");  
        fprintf(yyout, "\t.type %s, @object\n", $1);      
        fprintf(yyout, "\t.size %s, 4\n", $1);
        fprintf(yyout, "%s:\n", $1);
        fprintf(yyout, "\t.word %d\n", $3);
    }
    | VAR ASSIGN MALLOC INT ENTER
    {
        fprintf(yyout, "\t.comm %s, %d, 4\n", $1, $4);
    }
    ;

FUNCFunctionDef: 
    FunctionHeader Expressions FunctionEnd {}
    ;

FunctionHeader: 
    FUNC LBRK INT RBRK LBRK INT RBRK ENTER
    {
        STK = ($6 / 4 + 1) * 16;
        fprintf(yyout, "\t.text\n");
        fprintf(yyout, "\t.align 2\n");
        fprintf(yyout, "\t.global %s\n", $1);
        fprintf(yyout, "\t.type %s, @function\n", $1);      
        fprintf(yyout, "%s:\n", $1);
        fprintf(yyout, "\taddi sp, sp, %d\n", -STK);
        fprintf(yyout, "\tsw ra, %d(sp)\n", STK-4);
    }
    ;

FunctionEnd: 
    END FUNC ENTER
    {
	    fprintf(yyout, "\t.size %s, .-%s\n", $2, $2);
    }
    ;
    
Expressions: 
    Expressions Expression 
    | Expressions ENTER
    | { }
    ;

Expression: 
    REG ASSIGN INT ENTER
    {
        fprintf(yyout, "\tli %s, %d\n", $1, $3);
    }
    | REG ASSIGN REG OP REG ENTER
    {
        switch($4[0])
        {
            case '+':
                fprintf(yyout, "\tadd %s, %s, %s\n", $1, $3, $5);
                break;
            case '-':
                fprintf(yyout, "\tsub %s, %s, %s\n", $1, $3, $5);
                break;  
            case '*':
                fprintf(yyout, "\tmul %s, %s, %s\n", $1, $3, $5);
                break;  
            case '/':
                fprintf(yyout, "\tdiv %s, %s, %s\n", $1, $3, $5);
                break;  
            case '%':
                fprintf(yyout, "\trem %s, %s, %s\n", $1, $3, $5);
                break;  
            case '<':
                if (strcmp($4, "<=") == 0){
                    fprintf(yyout, "\tsgt %s, %s, %s\n", $1, $3, $5);
                    fprintf(yyout, "\tseqz %s, %s\n", $1, $1);
                }
                else{
                    fprintf(yyout, "\tslt %s, %s, %s\n", $1, $3, $5);
                }
                break;  
            case '>':
                if (strcmp($4, ">=") == 0){
                    fprintf(yyout, "\tslt %s, %s, %s\n", $1, $3, $5);
                    fprintf(yyout, "\tseqz %s, %s\n", $1, $1);
                }
                else{
                    fprintf(yyout, "\tsgt %s, %s, %s\n", $1, $3, $5);
                }
           
                break;  
            case '&':
                fprintf(yyout, "\tsnez %s, %s\n", $1, $3);
                fprintf(yyout, "\tsnez s0, %s\n", $5);
                fprintf(yyout, "\tand %s, %s, s0\n", $1, $1);
                break;  
            case '|':
                fprintf(yyout, "\tor %s, %s, %s\n", $1, $3, $5);
                fprintf(yyout, "\tsnez %s, %s\n", $1, $1);
                break;  
            case '!':
                fprintf(yyout, "\txor %s, %s, %s\n", $1, $3, $5);
                fprintf(yyout, "\tsnez %s, %s\n", $1, $1);
                break;  
            case '=':
                fprintf(yyout, "\txor %s, %s, %s\n", $1, $3, $5);
                fprintf(yyout, "\tseqz %s, %s\n", $1, $1);
                break;  
            default:
			    break;
        }
    }
    | REG ASSIGN REG OP INT ENTER
    {   
        
        switch($4[0])
        {
            case '+':
                fprintf(yyout, "\taddi %s, %s, %d\n", $1, $3, $5);
                break;
            case '<':
                if (strcmp($4, "<=") == 0){
                    fprintf(yyout, "\tli s0, %d\n", $5);
                    fprintf(yyout, "\tsgt %s, %s, s0\n", $1, $3);
                    fprintf(yyout, "\tseqz %s, %s\n", $1, $1);
                }
                else{
                    fprintf(yyout, "\tslti %s, %s, %d\n", $1, $3, $5);
                }
                break; 
                 
            case '-':
                fprintf(yyout, "\tli s0, %d\n", $5);
                fprintf(yyout, "\tsub %s, %s, s0\n", $1, $3);
                break;  
            case '*':
                fprintf(yyout, "\tli s0, %d\n", $5);
                fprintf(yyout, "\tmul %s, %s, s0\n", $1, $3);
                break;  
            case '/':
                fprintf(yyout, "\tli s0, %d\n", $5);
                fprintf(yyout, "\tdiv %s, %s, s0\n", $1, $3);
                break;  
            case '%':
                fprintf(yyout, "\tli s0, %d\n", $5);
                fprintf(yyout, "\trem %s, %s, s0\n", $1, $3);
                break;  
            case '>':
                if (strcmp($4, ">=") == 0){
                    fprintf(yyout, "\tli s0, %d\n", $5);
                    fprintf(yyout, "\tslt %s, %s, s0\n", $1, $3);
                    fprintf(yyout, "\tseqz %s, %s\n", $1, $1);
                }
                else{
                    fprintf(yyout, "\tli s0, %d\n", $5);
                    fprintf(yyout, "\tsgt %s, %s, s0\n", $1, $3);
                }
                break;  
            case '&':
                fprintf(yyout, "\tsnez %s, %s\n", $1, $3);
                fprintf(yyout, "\tsnez s0, s0\n");
                fprintf(yyout, "\tand %s, %s, s0\n", $1, $1);
                break;  
            case '|':
                fprintf(yyout, "\tli s0, %d\n", $5);
                fprintf(yyout, "\tor %s, %s, s0\n", $1, $3);
                fprintf(yyout, "\tsnez %s, %s\n", $1, $1);
                break;  
            case '!':
                fprintf(yyout, "\tli s0, %d\n", $5);
                fprintf(yyout, "\txor %s, %s, s0\n", $1, $3);
                fprintf(yyout, "\tsnez %s, %s\n", $1, $1);
                break;  
            case '=':
                fprintf(yyout, "\tli s0, %d\n", $5);
                fprintf(yyout, "\txor %s, %s, s0\n", $1, $3);
                fprintf(yyout, "\tseqz %s, %s\n", $1, $1);
                break; 
            default:
                break; 
        }
    }
    | REG ASSIGN OP REG ENTER
    {
        switch($3[0])
        {
            case '-':
                fprintf(yyout, "\tneg %s, %s\n", $1, $4);
                break;  
            case '!':
                fprintf(yyout, "\tseqz %s, %s\n", $1, $4);
                break;  
            default:
                break;
        }
    }
    | REG ASSIGN REG ENTER
    {
        fprintf(yyout, "\tmv %s, %s\n", $1, $3);
    }
    | REG LBRK INT RBRK ASSIGN REG ENTER
    {
        fprintf(yyout, "\tsw %s, %d(%s)\n", $6, $3, $1);
    }
    | REG ASSIGN REG LBRK INT RBRK ENTER
    {
        fprintf(yyout, "\tlw %s, %d(%s)\n", $1, $5, $3);
    }
    | IF REG OP REG GOTO LABEL ENTER
    {
        if (strcmp($3, "<")==0){
                fprintf(yyout, "\tblt %s, %s, .%s\n", $2, $4, $6);}
        else if (strcmp($3, ">")==0){
                fprintf(yyout, "\tbgt %s, %s, .%s\n", $2, $4, $6);}
        else if (strcmp($3, "<=")==0){
                fprintf(yyout, "\tble %s, %s, .%s\n", $2, $4, $6);}
        else if (strcmp($3, ">=")==0){
                fprintf(yyout, "\tbge %s, %s, .%s\n", $2, $4, $6);}
        else if (strcmp($3, "!=")==0){
                fprintf(yyout, "\tbne %s, %s, .%s\n", $2, $4, $6); } 
        else if (strcmp($3, "==")==0){
                fprintf(yyout, "\tbeq %s, %s, .%s\n", $2, $4, $6);}
    } 
    | GOTO LABEL ENTER
    {
        fprintf(yyout, "\tj .%s\n", $2);
    }
    | LABEL COL ENTER
    {
        fprintf(yyout, ".%s:\n", $1);
    }
    | CALL FUNC ENTER
    {
        fprintf(yyout, "\tcall %s\n", $2);
    }
    | RETURN ENTER
    {
        fprintf(yyout, "\tlw ra, %d(sp)\n", STK-4);
        fprintf(yyout, "\taddi sp, sp, %d\n", STK);
        fprintf(yyout, "\tret\n");

    }
    | STORE REG INT ENTER
    {
        fprintf(yyout, "\tsw %s, %d(sp)\n", $2, $3*4);
    }
    | LOAD INT REG ENTER
    {
        fprintf(yyout, "\tlw %s, %d(sp)\n", $3, $2*4);
    }
    | LOAD VAR REG ENTER
    {
        fprintf(yyout, "\tlui %s, %%hi(%s)\n", $3, $2);
        fprintf(yyout, "\tlw %s, %%lo(%s)(%s)\n", $3, $2, $3);
    }
    | LOADARRD INT REG ENTER
    {
        fprintf(yyout, "\taddi %s, sp, %d\n", $3, $2*4);
    }
    | LOADARRD VAR REG ENTER
    {
        fprintf(yyout, "\tla %s, %s\n", $3, $2);
    }
    ;
%%
