%{
    #include<string.h>
    #include<stdio.h>
    #include<stdlib.h>
    #include"yacc.tab.hpp"
    void yyerror(const char*);
    int lineno = 1;
%}

integer     (-)?[0-9]+
name_string [a-zA-Z_]([a-zA-Z_0-9])*
func        f_{name_string}
label       l{integer}
var         v{integer}
reg         (a[0-7]|s[0-9]|s10|s11|t[0-6]|x0)

%%

":"           return COL;
"["         return LBRK;
"]"         return RBRK;
"if"          return IF;
"goto"        return GOTO;
"return"      return RETURN;
"call"        return CALL;
"store"       return STORE;
"load"        return LOAD;
"loadaddr"    return LOADARRD;
"malloc"      return MALLOC;
"end"         return END;
"="           return ASSIGN;

"!="          {yylval.str=strdup(yytext); return OP;}
"=="          {yylval.str=strdup(yytext); return OP;}
"<"           {yylval.str=strdup(yytext); return OP;}
">"           {yylval.str=strdup(yytext); return OP;}
"<="          {yylval.str=strdup(yytext); return OP;}
">="          {yylval.str=strdup(yytext); return OP;}
"+"           {yylval.str=strdup(yytext); return OP;}
"-"           {yylval.str=strdup(yytext); return OP;}
"*"           {yylval.str=strdup(yytext); return OP;}
"/"           {yylval.str=strdup(yytext); return OP;}
"!"           {yylval.str=strdup(yytext); return OP;}
"&&"          {yylval.str=strdup(yytext); return OP;}
"||"          {yylval.str=strdup(yytext); return OP;}
"%"           {yylval.str=strdup(yytext); return OP;}


{label}       {yylval.str=strdup(yytext); return LABEL;}
{func}        {yylval.str=strdup(yytext+2); return FUNC;}
{reg}         {yylval.str=strdup(yytext); return REG;}
{var}         {yylval.str=strdup(yytext); return VAR;}
{integer}     {yylval.num=atoi(yytext); return INT;}
[\n]	    { lineno++; return ENTER; }
[ \t]+                 /* ignore whitespace */;
"//"[^\n]*                 /* ignore comment */;
. {}
%%

int yywrap() 
{ 
   return(1); 
}

int main(int argc, char** argv)
{
    if((yyin=fopen(argv[2],"r"))==NULL)
            exit(1);
    yyout=fopen(argv[4],"w");
    yyparse();
    fclose(yyin);
    fclose(yyout);
    return 0;
} 

