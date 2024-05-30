/* PROGRAMMER: Abigail Kelly
 * PROGRAM #: Project 4
 * DUE DATE: Friday, 3/22/23
 * INSTRUCTOR: Dr. Zhijiang Dong
 * This program will create an abstract syntax tree for the
 * input COOL program file
 */

%debug
%verbose

%code requires {
#include <iostream>
#include "ErrorMsg.h"
#include "StringTab.h"
#include "Absyn.h"

using namespace absyn;
}

/* The following UNION defines data type for the semantic values of 
 * all language constructs (i.e. non-terminals and terminals).
 *
 */
%union {
	Symbol			symbol;		//to store the index of symbol in literal tables like intTable, stringTable, and idTable.
	bool			boolean;	//to store boolean constants
	Program			program;	//to store the object representing a COOL program
	Class_			class_;		//to store the definition of one COOL class
	Classes			classes;	//to represent a list of COOL classes
	Feature			feature;	//to store one feature (i.e. method or attribute) definition of a class
	Features		features;	//to represent a list of features
	Formal			formal;		//to store a formal parameter including parameter name and type
	Formals			formals;	//to represent the list of formals for a method
	Branch			branch;		//to store one branch of case expression in COOL
	Branches		branches;	//to represent the list of case branches in a case expression
	Expression		expression;	//to store one expression
	Expressions		expressions;//to represent a list of expressions
}

%{
extern string curr_filename;	//current file name

int yylex(void); /* function prototype */
void yyerror(char *s);	//called by the parser whenever an eror occurs

template<typename Item>
List<Item>* single_list(Item i);	//create a list of one item only

template<typename Item>
List<Item>* pair_list(Item head, List<Item>* rest);	//create a list of two items: head and tail
													//tail itself is a list


Program root;			/* the root of generated abstract syntax tree */
%}


/* Declare types for the grammar's non-terminals. */
///////////////////////////////////////////////////////////////////
/* I use the following non-terminals. You need to replace them with 
 * your own non-terminals. Make sure these non-terminals and ones
 * used in your CFG rules are consistent.
 */
///////////////////////////////////////////////////////////////////
%type <program>		program
%type <classes>		class_list
%type <class_>		class
%type <features>	feature_list optional_feature_list
%type <feature>		feature
%type <formals>		optional_formal_list formal_list
%type <formal>		formal
%type <expression>	expr optional_initialization let_list
%type <expressions> gt1_expr_list optional_expr_list expr_list
%type <branches>	case_list 
%type <branch>		simple_case

/* Declare types for the grammar's terminals. */
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


program	: class_list
		  { root = new Program_class(@1.first_line, @1.first_column, $1); }	  
        ;

class_list 	
		:	class			
			{ $$ = single_list($1); }
		|	class class_list	// several classes
			{ $$ = pair_list($1, $2); }
		;

// If no parent is specified, the class inherits from the Object class.
class	:	CLASS TYPEID '{' optional_feature_list '}' ';'
			{ $$ = new Class_class(@1.first_line, @1.first_column, 
									stringtable.add_string(curr_filename),
									$2, idtable.add_string("Object"), $4); }
		|	CLASS TYPEID INHERITS TYPEID '{' optional_feature_list '}' ';'
			{ $$ = new Class_class(@1.first_line, @1.first_column, 
									stringtable.add_string(curr_filename),
									$2, $4, $6); }
		;

/* optional feature list rule */
optional_feature_list
		:	/* can be empty */	
            { $$ = nullptr; }
        |	feature_list
            { $$ = $1; }
        ;

/* feature list rule */
feature_list 
		:	feature                          /* can contain one feature */
            { $$ = single_list($1); }
        |	feature feature_list             /* or can contain multiple features */
            { $$ = pair_list($1, $2); }
        ;

/* feature rule */
feature :	OBJECTID '(' optional_formal_list ')' ':' TYPEID '{' expr '}' ';' 
            { $$ = new Method(@1.first_line, @1.first_column, $1, $3, $6, $8); }
        |	OBJECTID ':' TYPEID ';'
            { $$ = new Attr(@1.first_line, @1.first_column, $1, $3); }
        |	OBJECTID ':' TYPEID ASSIGN expr ';'
            { $$ = new Attr(@1.first_line, @1.first_column, $1, $3, $5); }
        ;

/* optional formal list rule */
optional_formal_list 
		:	/* can be empty */
            { $$ = nullptr; }
        |	formal_list
            { $$ = $1; }
        ;

/* formal list rule */
formal_list 
		:	formal                            /* can contain one formal */
            { $$ = single_list($1); }
        |	formal ',' formal_list            /* or can contain multiple formals */
            { $$ = pair_list($1, $3); }
        ;

/* formal rule */
formal	:	OBJECTID ':' TYPEID
            { $$ = new Formal_class(@1.first_line, @1.first_column, $1, $3); }
        ;

expr    :   OBJECTID ASSIGN expr
            { $$ = new AssignExp(@1.first_line, @1.first_column, $1, $3); }
        |   expr '.' OBJECTID '(' optional_expr_list ')'
            { $$ = new CallExp(@1.first_line, @1.first_column, $1, $3, $5); }
        |   expr '@' TYPEID '.' OBJECTID '(' optional_expr_list ')'
            { $$ = new StaticCallExp(@1.first_line, @1.first_column, $1, $3, $5, $7); }
        |   OBJECTID '(' optional_expr_list ')'     //THIS IS NOT RIGHT!!!
            { Expression self_obj = new absyn::ObjectExp(@1.first_line, 
                                                        @1.first_column, 
                                                        idtable.add_string("self"));
              $$ = new CallExp(@1.first_line, @1.first_column, self_obj,
                               $1, $3); }   
        |   IF expr THEN expr ELSE expr FI        /* if statement */
            { $$ = new IfExp(@1.first_line, @1.first_column, $2, $4, $6); }
        |   WHILE expr LOOP expr POOL             /* while loop */                     
            { $$ = new WhileExp(@1.first_line, @1.first_column, $2, $4); }
        |   '{' gt1_expr_list '}'                 /* occurs at least once */
            { $$ = new BlockExp(@1.first_line, @1.first_column, $2); }
        |   LET let_list
            { $$ = $2; }
        |   CASE expr OF case_list ESAC           /* case expression */
            { $$ = new CaseExp(@1.first_line, @1.first_column, $2, $4); }
        |   NEW TYPEID
            { $$ = new NewExp(@1.first_line, @1.first_column, $2); }
        |   ISVOID expr
            { $$ = new IsvoidExp(@1.first_line, @1.first_column, $2); }
        |   expr '+' expr                         /* mathematical operations */
            { $$ = new OpExp(@1.first_line, @1.first_column, $1, OpExp::PLUS, $3); }
        |   expr '-' expr
            { $$ = new OpExp(@1.first_line, @1.first_column, $1, OpExp::MINUS, $3); }
        |   expr '*' expr
            { $$ = new OpExp(@1.first_line, @1.first_column, $1, OpExp::MUL, $3); }
        |   expr '/' expr
            { $$ = new OpExp(@1.first_line, @1.first_column, $1, OpExp::DIV, $3); }
        |   '~' expr
            { $$ = new OpExp(@1.first_line, @1.first_column, 
                             (new IntExp(@1.first_line, @1.first_column, inttable.add_int(0))), 
                             OpExp::MINUS, $2); }
        |   expr '<' expr                         /* comparisons */
            { $$ = new OpExp(@1.first_line, @1.first_column, $1, OpExp::LT, $3); }
        |   expr LE expr
            { $$ = new OpExp(@1.first_line, @1.first_column, $1, OpExp::LE, $3); }
        |   expr '=' expr
            { $$ = new OpExp(@1.first_line, @1.first_column, $1, OpExp::EQ, $3); }
        |   NOT expr
            { $$ = new NotExp(@1.first_line, @1.first_column, $2); }
        |   '(' expr ')'
            { $$ = $2; }
        |   OBJECTID
            { $$ = new ObjectExp(@1.first_line, @1.first_column, $1); }
        |   INT_CONST
            { $$ = new IntExp(@1.first_line, @1.first_column, $1); }
        |   STR_CONST
            { $$ = new StringExp(@1.first_line, @1.first_column, $1); }
        |   BOOL_CONST
            { $$ = new BoolExp(@1.first_line, @1.first_column, $1); }
        ;

optional_initialization
        :   /* can be empty */
            { $$ = nullptr; }
        |   ASSIGN expr
            { $$ = $2; }        //NOT SURE ABOUT THIS!!!
        ;
/* let list rule */
let_list
        :   OBJECTID ':' TYPEID optional_initialization IN expr %prec LET_STMT
            { $$ = new LetExp(@1.first_line, @1.first_column, $1, $3, $4, $6); }
        |   OBJECTID ':' TYPEID optional_initialization ',' let_list 
            { $$ = new LetExp(@1.first_line, @1.first_column, $1, $3, $4, $6); }
        ;


/* case list rule */
case_list
        :   simple_case /* One branch */
            { $$ = single_list($1); }
        |   simple_case case_list 
            { $$ = pair_list($1, $2); }
        ;
simple_case 
        :   OBJECTID ':' TYPEID DARROW expr ';'
            { $$ = new Branch_class(@1.first_line, @1.first_column, $1, $3, $5); }
        ;

gt1_expr_list 
        :   expr ';'
            { $$ = single_list($1); }
        |   expr ';' gt1_expr_list
            { $$ = pair_list($1, $3); }
        ;

optional_expr_list 
        :   /* can be empty */
            { $$ = nullptr; }
        |   expr_list
            { $$ = $1; }
        ;

/* expression list rule */
expr_list 
        :   expr                                /* can happen once */
            { $$ = single_list($1); }
        |   expr ',' expr_list                  /* can happen multiple times */
            { $$ = pair_list($1, $3); }
        ;

////////////////////////////////////////////////////////////////////////////
/*
 * Copy CFG Rules from previous assignment here, and remove all rules for error recovery.
 * Make sure your non-terminals are consistent with ones defined in above.
 * For each rule, please define actions to construct AST.
 *
 *  Tips for the project:
 *	• In this project, the action for almost all rules is to construct the parse trees represented by the production head. More specifically, the action should look like: $$ = …., i.e. trying to assign a value to $$, the value associated to the production head. Before implementing the action for a rule, please make sure you understand the type of value associated to the production head. Most actions are just one statement.
 *	• The production body for certain rules is empty, such as
 *		Optional_expr_list:  // empty body  
							{ $$ = nullptr; }
 *						  | expr ‘;’ expr_list
 *			              ;
 *	  For such rules, the action should be: $$ = nullptr;
 *	• For production expr : ~ expr where ~ represents complement of expr. You should interpret it as 
 *	  0 – expr. In the action, you should use: new IntExp(@1.first_line, @1.first_column, inttable.add_int(0)) to represent 0.
 *	• The production: expr -> OBJECTID ‘(‘optional_expr_list_with_comma ‘)’ represents a method call. 
 *    But in the constructor of CallExp, an object is required. Semantically, it should be the self object. 
 *    So in the action of this rule, you need to construct a self_obj first as shown below:
 *
 *		Expression self_obj = new absyn::ObjectExp(@1.first_line, @1.first_column, 
 *													idtable.add_string("self"));
 *
 *	• Please use provided single_list and pair_list functions to construct list.
 */
//////////////////////////////////////////////////////////////////////////

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

template<typename Item>
List<Item>* single_list(Item i) 
{
	return new List<Item>(i, nullptr);
}

template<typename Item>
List<Item>* pair_list(Item head, List<Item>* rest)
{
	return new List<Item>(head, rest);
}
