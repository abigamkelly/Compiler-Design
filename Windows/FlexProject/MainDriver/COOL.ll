/* PROGRAMMER: Abigail Kelly
 * PROGRAM #: project 2
 * DUE DATE: Wednesday, 2/15/23
 * INSTRUCTOR: Dr. Zhijiang Dong
 *
 * This program uses flex (a scanner generator) to generate a scanner for
 * COOL language.
 */


%option noyywrap
%option c++
%option never-interactive
%option nounistd
%option yylineno

%{
#include <iostream>
#include <string>
#include <sstream>
#include "tokens.h"
#include "ErrorMsg.h"

using std::string;
using std::stringstream;

ErrorMsg	errormsg;			//objects to trace lines and chars per line so that
								//error message can refer the correct location 
int		comment_depth = 0;		// depth of the nested comment
string	buffer = "";			// the buffer to hold part of string that has been recognized

void newline(void);				//trace the line #
void error(int, int, string);	//output the error message referring to the current token

int			line_no = 1;		//line no of current matched token
int			column_no = 1;		//column no of the current matched token

int			tokenCol = 1;		//column no after the current matched token

int			beginLine=-1;		//beginning position of a string or comment
int			beginCol=-1;		//beginning position of a string or comment

//YY_USER_ACTION will be executed after each Rule is used. Good to track locations.
#define YY_USER_ACTION {column_no = tokenCol; tokenCol=column_no+yyleng;}
%}


/* defined regular expressions */
NEWLINE			[\n]
WHITESPACES		[ \t\f\v\r]
TYPESYMBOL		[A-Z][_A-Za-z0-9]*
OBJECTSYMBOL	[a-z][_A-Za-z0-9]*

/*exclusive start conditions to recognize comment and string */
%x COMMENT
%x LINE_COMMENT
%x STRING


%%
{NEWLINE}			{ newline(); }
{WHITESPACES}+		{}


 /*
  *  If it is a token with a single character, just return the character itself.
  */
"+"	        { return '+'; }
"-"			{ return '-'; }
"*"			{ return '*'; }
"/"			{ return '/'; }
"="			{ return '='; }
"@"			{ return '@'; }
"."			{ return '.'; }
","			{ return ','; }
";"			{ return ';'; }
":"			{ return ':'; }
"{"			{ return '{'; }
"}"			{ return '}'; }
"("			{ return '('; }
")"			{ return ')'; }
"~"			{ return '~'; }
"<"			{ return '<'; }

 /*
  *  The multiple-character operators.
  */
"=>"				{ return (DARROW); }
"<="				{ return (LE); }
"<-"				{ return (ASSIGN); }

 /*
  *  integers should be added to the "intTable" (check stringtab.h file) 
  *  so that there is only one copy of the same interger literal.
  *  Similarly, string literals should be added to "stringTable", and 
  *  typeid and objectid should be added to "idTable".
  *	 
  *	 yylval is a variable of YYSTYPE structure is used to hold values 
  *	 of tokens if a token is a collection of lexemes.
  *
  *  check YYSTYPE definition in tokens.h
  */

  /* add integer to table nad return the token */
[0-9][0-9]*			{ yylval.symbol = intTable.add_string(YYText()); return INTCONST; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
[Cc][Aa][Ss][Ee]					{ return (CASE); }
[Cc][Ll][Aa][Ss][Ss] 				{ return (CLASS); }
[Ee][Ll][Ss][Ee]					{ return (ELSE); }
[Ee][Ss][Aa][Cc]					{ return (ESAC); }
[Ii][Ff]							{ return (IF); }
[Tt][Hh][Ee][Nn]					{ return (THEN); }
[Ff][Ii]							{ return (FI); }
[Ll][Oo][Oo][Pp]					{ return (LOOP); }
[Pp][Oo][Oo][Ll]					{ return (POOL); }
[Ii][Nn]							{ return (IN); }
[Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss]	{ return (INHERITS); }
[Ii][Ss][Vv][Oo][Ii][Dd]			{ return (ISVOID); }
[Ll][Ee][Tt]						{ return (LET); }
[Ww][Hh][Ii][Ll][Ee]				{ return (WHILE); }
[Nn][Ee][Ww]						{ return (NEW); }
[Oo][Ff]							{ return (OF); }
[Nn][Oo][Tt]						{ return (NOT); }
t[Rr][Uu][Ee]						{ yylval.boolean = true; return BOOLCONST; }		/* must update for boolean constants */
f[Aa][Ll][Ss][Ee]					{ yylval.boolean = false; return BOOLCONST; }

 /*
  * Add all missing rules here
  *
  */

{TYPESYMBOL} 						{ yylval.symbol = idTable.add_string(YYText()); return TYPEID; }

{OBJECTSYMBOL} 						{ yylval.symbol = idTable.add_string(YYText()); return OBJECTID; }   /* Adds objectid to idtable */

\"									{   /* recognizes beginning of a string */
										buffer = "";				/* initialize the buffer */
										beginLine = line_no;		/* initialize the line and column numbers to starting position */
										beginCol = column_no; 
										BEGIN(STRING);				/* start STRING condition */
									}

<STRING>\\t							{ buffer += "\t"; }				/* recognizes \t and appends to buffer */	
<STRING>\\n							{ buffer += "\n"; }				/* recognizes \n and appends to buffer */
<STRING>\\\\						{ buffer += "\\"; }				/* recognizes \\ and appends to buffer */
<STRING>\\\"						{ buffer += "\""; }				/* recognizes \" and appends to buffer */				

<STRING>\\\n						{	/* multiple lined string (recognizes non-escaped newline character) */
										buffer += ""; 
										newline();
									}				

<STRING>\n							{   /* rule for unclosed string */
										BEGIN(INITIAL);						/* start INITIAL condition */
										newline();
										yylval.symbol = stringTable.add_string(buffer);		/* add the string to the stringTable */
										error(beginLine, beginCol, "Unterminated string constant");		/* display the error */
										buffer = "";										/* clear the buffer */
										return STRCONST;									/* return the token */
									}

<STRING>\\b							{ /* backspace; legal for strings in cool, ignore it */ }

<STRING>\"							{   /* rule that recognizes the end of a string */		
										yylval.symbol = stringTable.add_string(buffer);	/* add the string to the stringTable */
										BEGIN(INITIAL);						/* start the INITIAL condition */
										buffer = "";						/* clear the buffer */
										return STRCONST;					/* return the token */
									}	

<STRING>\\.							{	/* rule that captures illegal escape sequences  (every legal escape sequence has been caught, so all that's left are illegal */
										buffer += YYText();	
										error(line_no, column_no, string(YYText()) +" illegal escape sequence");	/* display the error */
									}  
																								 

<STRING>.							{ buffer += YYText(); }					/* rule that recognizes the rest of the string */

"(*"								{	/* recognizes comment; entering comment */
										comment_depth +=1;		/* increment depth of comment */
										beginLine = line_no;	/* update line and column numbers */
										beginCol = column_no;
										BEGIN(COMMENT);			/* begin COMMENT start condition */
									}

<COMMENT>"(*"						{	/* nested comment */
										comment_depth ++;
									}

<COMMENT>[^*)(\n]*					{	/*eat string that's not a '*', '(', ')' */ }

<COMMENT>"("+[^*)\n]*				{	/*eat string that starts with ( but not followed by '*' and ')' */ }

<COMMENT>[^*(\n]*")"+				{	/*eat string that doesn't contain '*' and '(' but ends with a sequence of ')' */ }

<COMMENT>"*"+[^*)(\n]*				{	/* eat string that starts with a sequence of * followed by anything other than '*', '(', ')' */	}

<COMMENT>\n							{	/* trace line # and reset column related variable */
										line_no++; 
										column_no = tokenCol = 1;
									}

<COMMENT>"*"+")"					{	/* close of a comment */
										comment_depth --;
										if ( comment_depth == 0 )
										{
											BEGIN(INITIAL);	
										}
									}

<COMMENT><<EOF>>					{	/* unclosed comments */
										error(beginLine, beginCol, "unclosed comments");
										yyterminate();
									}

<<EOF>>								{	yyterminate();	}		/* rule for end of file */

.									{	error(line_no, column_no, "illegal token"); }		/* recognizes illegal token */

"*)"								{ error(line_no, column_no, "Unmatched *)"); }			/* recognizes unmatched token */

"--".*								{ /* do nothing (single line comment) */ 
										BEGIN(LINE_COMMENT);	/* starts LINE_COMMENT start condition */
									}

<LINE_COMMENT>\n					{
										newline();		/* end of line comment */
										BEGIN(INITIAL);
									}			


%%

void newline()
{
	line_no ++;
	column_no = 1;
	tokenCol = 1;
}

void error(int line, int col, string msg)
{
	errormsg.error(line, col, msg);
}
