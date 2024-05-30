/* PROGRAMMER: Abigail Kelly
 * PROGRAM #: Project 3
 * DUE DATE: Friday, 3/3/23
 * INSTRUCTOR: Dr. Zhijiang Dong
 * This program will act as a CFG for the COOL programming language
 */


%debug
%verbose
%locations

%code requires {
#include <iostream>
#include "ErrorMsg.h"
#include "StringTab.h"

int yylex(void); /* function prototype */
void yyerror(char *s);	//called by the parser whenever an eror occurs

}

%union {
	bool		boolean;	
	Symbol		symbol;	
}

%token <symbol>		STR_CONST TYPEID OBJECTID INT_CONST 
%token <boolean>	BOOL_CONST

%token CLASS ELSE FI IF IN 
%token INHERITS LET LOOP POOL THEN WHILE 
%token CASE ESAC OF DARROW NEW ISVOID 
%token ASSIGN NOT LE 

/* Precedence declarations. */
%left LET_STMT
%right ASSIGN
%left NOT
%nonassoc LE '<' '='
%left '-' '+'
%left '*' '/'
%left ISVOID
%left '~'
%left '@'
%left '.'

%start program

%%

/*
 * The following is CFG of COOL programming languages. Several simple rules in the following comments are given for demonstration purpose.
 * You can uncomment them and provide extra rules for the CFG. Please be noted that you uncomment without providing extra rules, BISON will
 * will report errors when compiling COOL.yy file since several non-terminals are not defined.
 * 
 
 * No rule action needed in this assignment 
 * If a recusive rule is needed, for example, define a list of something, always use 
 * right recursion like:
 * class_list : class class_list
 *
 */


/* A COOL program is viewed as a list of classes */
program	: class_list
        ;

class_list : class	
        | error ';'                             /* error in the first class */
		| class class_list                      /* several classes */
        | class_list error ';'                  /* error message */
		;

/* class rule */
class : CLASS TYPEID '{' optional_feature_list '}' ';'
		| CLASS TYPEID INHERITS TYPEID '{' optional_feature_list '}' ';'
		;

/* optional feature list rule */
optional_feature_list: /* can be empty */		       
        | feature_list
        ;
        
/* feature list rule */
feature_list : feature                          /* can contain one feature */
        | feature feature_list                  /* or can contain multiple features */
        ;
        
/* feature rule */
feature : OBJECTID '(' optional_formal_list ')' ':' TYPEID '{' expr '}' ';'                          
        | OBJECTID ':' TYPEID ';'
        | OBJECTID ':' TYPEID ASSIGN expr ';'
        ;

/* optional formal list rule */
optional_formal_list : /* can be empty */
        | formal_list
        ;

/* formal list rule */
formal_list : formal                            /* can contain one formal */
        | formal ',' formal_list                /* or can contain multiple formals */
        ;

/* formal rule */
formal : OBJECTID ':' TYPEID
        ;
/* expression rule */
expr : error
        | OBJECTID ASSIGN expr
        | expr '.' OBJECTID '(' optional_expr_list ')'
        | expr '@' TYPEID '.' OBJECTID '(' optional_expr_list ')'
        | OBJECTID '(' optional_expr_list ')'
        | IF expr THEN expr ELSE expr FI        /* if statement */
        | WHILE expr LOOP expr POOL             /* while loop */
        | '{' gt1_expr_list '}'                 /* occurs at least once */
        | LET OBJECTID ':' TYPEID optional_let_list IN expr
        | LET OBJECTID ':' TYPEID ASSIGN expr optional_let_list IN expr
        | CASE expr OF case_list ESAC           /* case expression */
        | NEW TYPEID
        | ISVOID expr
        | expr '+' expr                         /* mathematical operations */
        | expr '-' expr
        | expr '*' expr
        | expr '/' expr
        | '~' expr
        | expr '<' expr                         /* comparisons */
        | expr LE expr
        | expr '=' expr
        | NOT expr
        | '(' expr ')'
        | OBJECTID
        | INT_CONST
        | STR_CONST
        | BOOL_CONST
        ;
        
/* optional let list rule */     
optional_let_list : /* can be empty */
        | let_list   
        ;

/* let list rule */       
let_list : ',' OBJECTID ':' TYPEID              /* can happen once */
        |',' OBJECTID ':' TYPEID ASSIGN expr
        |',' OBJECTID ':' TYPEID let_list       /* can happen multiple times */
        |',' OBJECTID ':' TYPEID ASSIGN expr let_list
        ;

/* case list rule */
case_list : OBJECTID ':' TYPEID DARROW expr ';'
        | OBJECTID ':' TYPEID DARROW  expr ';' case_list
        ;

/* rule for expression list that happens atleast once */
gt1_expr_list : expr ';'
        | expr ';' gt1_expr_list
        ;

/* optional expression list rule */
optional_expr_list : /* can be empty */
        | expr_list
        ;
   
/* expression list rule */
expr_list : expr                                /* can happen once */
        | expr ',' expr_list                    /* can happen multiple times */
        ;


/* end of grammar */

%%
#include <FlexLexer.h>
extern yyFlexLexer	lexer;
int yylex(void)
{
	return lexer.yylex();
}

void yyerror(char *s)
{	
	extern ErrorMsg errormsg;
	errormsg.error(yylloc.first_line, yylloc.first_column, s);
}