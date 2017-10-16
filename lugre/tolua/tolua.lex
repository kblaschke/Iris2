/* converts c++ header to lugre lua bindings */

%option noyywrap

%{
/* need this for the call to atof() below */

#include <math.h>

#include <stdio.h>
FILE *f;

%}

DIGIT    	[0-9]
NONDIGIT	[a-zA-Z]
ALLDIGIT	{DIGIT}|{NONDIGIT}|[-_:~]
ID       	{NONDIGIT}+{ALLDIGIT}*
SP			[ \r\n\t]+
PSP			[ \r\n\t]*
LE			{SP}*\n
STAR		{PSP}[\*&]{PSP}
T			{ID}{SP}|{ID}{PSP}{STAR}+{PSP}

NAMESPACE	namespace{SP}{ID}{PSP}"{"
CLASS		class{SP}{ID}[^;\{]*"{"
FUNCTION	{T}{ID}{PSP}"("[^\)]*")"
DESTRUCTOR	~{ID}{PSP}"("[^\)]*")"
CONSTRUCTOR	{ID}{PSP}"("[^\)]*")"

%x comment
%x nonpublic

%%

<INITIAL>"//"[^\n]*			// one line comments
<INITIAL>"#"[^\n]*			// # lines

<*>"/*"						{BEGIN(comment);}
<comment>"*"+[^*/\n]*  		// multilines comment stuff /* eat up '*'s not followed by '/'s */
<comment>\n             
<comment>.             
<comment>"*"+"/"     		{BEGIN(INITIAL);}

<nonpublic>{NAMESPACE}		{BEGIN(INITIAL);}
<nonpublic>{CLASS}			{BEGIN(INITIAL);}
<nonpublic>{FUNCTION}|{DESTRUCTOR}|{CONSTRUCTOR}	// skip

<INITIAL>protected:			{BEGIN(nonpublic);}
<INITIAL>private:			{BEGIN(nonpublic);}
<nonpublic>public:			{BEGIN(INITIAL);}

<INITIAL>{NAMESPACE}		{fprintf(f, "#namespace: %s\n", yytext );}
<INITIAL>{CLASS}			{fprintf(f, "#class: %s\n", yytext );}
<INITIAL>{FUNCTION}			{fprintf(f, "#function: %s\n", yytext );}
<INITIAL>{DESTRUCTOR}		{fprintf(f, "#destructor: %s\n", yytext );}
<INITIAL>{CONSTRUCTOR}		{fprintf(f, "#constructor: %s\n", yytext );}

{LE}						// {printf("LE: [%s]\n",yytext);}

.							// {printf("?: [%s]\n",yytext);}

%%

main( argc, argv )
int argc;
char **argv;
{
	++argv, --argc;  /* skip over program name */
	
	if ( argc == 2 ){
		 yyin = fopen( argv[0], "r" );
		 f = fopen( argv[1], "w");
	} else {
		return 1;
	}

	yylex();
	
	fclose(f);
}
