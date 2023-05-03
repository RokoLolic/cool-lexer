/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%option noyywrap 
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <string.h>
/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int comment_level =0;
int string_lenght =0;
%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
DIGIT	[0-9]
LETTER [A-Za-Z]
TRUE t[Rr][Uu][Ee] 
FALSE f[Aa][Ll][Ss][Ee]

LE "<="
CLASS [Cc][Ll][Aa][Ss][Ss]
ELSE [Ee][Ll][Ss][Ee]
FI [Ff][Ii]
IF [Ii][Ff]
IN [Ii][Nn]
INHERITS [Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss]
ISVOID [Ii][Ss][Vv][Oo][Ii][Dd]
LET [Ll][Ee][Tt]
LOOP [lL][oO][oO][pP]
POOL [pP][oO][oO][lL]
THEN [tT][hH][eE][nN]
WHILE [wW][hH][iI][lL][eE]
CASE [cC][aA][sS][eE]
ESAC [Ee][Ss][Aa][Cc] 
NEW [Nn][Ee][Ww]
OF [Oo][Ff]
NOT [Nn][Oo][Tt]

/*ASSIGN [Aa][Ss][Ss][Ii][Gg][Nn]*/
%x COMMENTBRACKET
%x COMMENTLINES
%x STRING
%x IGNORENEXT
%x STRINGTOOLONG
/*PUNCTUATION [\{\}\(\)\:]*/
%%

 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */

"(*" {BEGIN COMMENTBRACKET; comment_level++;}
"--" {BEGIN COMMENTLINES;}

{DARROW}		{ return (DARROW); }
{CLASS} {return (CLASS);}
{ELSE} {return (ELSE);}
{FI} {return (FI);}
{IF} {return (IF);}
{IN} {return (IN);}
{INHERITS} {return (INHERITS);}
{ISVOID} {return (ISVOID);}
{LET} {return (LET);}
{LOOP} {return (LOOP);}
{POOL} {return (POOL);}
{THEN} {return (THEN);}
{WHILE} {return (WHILE);}
{CASE} {return (CASE);}
{ESAC} {return (ESAC);}
{NEW} {return (NEW);}
{OF} {return (OF);}
{NOT} {return (NOT);}
{LE} {return (LE);}

{TRUE} {cool_yylval.boolean = true;
         return (BOOL_CONST);}
{FALSE} {cool_yylval.boolean = false; return (BOOL_CONST);}
{DIGIT}+ {cool_yylval.symbol = inttable.add_string(yytext); return INT_CONST;}
[A-Z][A-Za-z0-9_]* {cool_yylval.symbol = stringtable.add_string(yytext);
    return TYPEID;}
[a-z][A-Za-z0-9_]* {cool_yylval.symbol= stringtable.add_string(yytext); 
    return(OBJECTID);}
\" { string_buf_ptr=string_buf;
  BEGIN STRING;}

"<-" {return (ASSIGN);}
\n {curr_lineno++;}
[" "\t\r] {}

[\!\#\$\%\^\&\_\>\?\`\[\]\\\|] {cool_yylval.error_msg = yytext; return ERROR;}
"*)" {cool_yylval.error_msg = "Unmatched *)"; return ERROR;}

<STRING>{
  \" {BEGIN INITIAL;
    cool_yylval.symbol= stringtable.add_string(string_buf);
    memset(string_buf,0,sizeof(string_buf));
    string_lenght = 0;
    return(STR_CONST);}
  \\/n {
    *string_buf_ptr = 0x0A;
    string_buf_ptr++;
    if(string_lenght >= MAX_STR_CONST){
      cool_yylval.error_msg = "String constant too long";
      BEGIN STRINGTOOLONG;
      return ERROR;
    }
    string_lenght++;
    BEGIN IGNORENEXT;
  }
  \\/t {
    *string_buf_ptr = 0x09;
    string_buf_ptr++;
    if(string_lenght >= MAX_STR_CONST){
      cool_yylval.error_msg = "String constant too long";
      BEGIN STRINGTOOLONG;
      return ERROR;
    }

    string_lenght++;

    BEGIN IGNORENEXT;
  }
  
  \n {
    curr_lineno++;
  }

  . {
    *string_buf_ptr=yytext[0];
    string_buf_ptr++;
    if(string_lenght >= MAX_STR_CONST){
      cool_yylval.error_msg = "String constant too long";
      BEGIN STRINGTOOLONG;
      return ERROR;
    }
    string_lenght++;
    
    }
}
<STRINGTOOLONG>{
  . {}
  \" {BEGIN INITIAL;} 
}
<IGNORENEXT>{
  . {BEGIN STRING;}
}
<COMMENTBRACKET>{
  "(*" {comment_level++;}
  "*)" {comment_level--;
      if(comment_level==0){
        BEGIN INITIAL;
        }
  } 
  \n {curr_lineno++;}
  . {}
}
<COMMENTLINES>{
  \n {curr_lineno++; BEGIN INITIAL;}
  . {}
}
. {return (yytext[0]);}
 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%
