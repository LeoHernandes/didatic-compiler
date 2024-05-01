/* Desenvolvido pelo Grupo K
    - LEO HERNANDES DE VASCONCELOS - 323961
    - VITOR CARUSO RODRIGUES FERRER - 327023
*/

%{
int yylex(void);
void yyerror (char const *mensagem);
extern void *ast_root;
%}

%define parse.error verbose
%code requires {#include "ast.h"}


%union {
  lexical_data_t *value;
  ast_t *tree_node;
}

%token TK_PR_INT
%token TK_PR_FLOAT
%token TK_PR_BOOL
%token TK_PR_IF
%token TK_PR_ELSE
%token TK_PR_WHILE
%token TK_PR_RETURN
%token TK_OC_LE
%token TK_OC_GE
%token TK_OC_EQ
%token TK_OC_NE
%token TK_OC_AND
%token TK_OC_OR

%token<value> TK_IDENTIFICADOR
%token<value> TK_LIT_INT
%token<value> TK_LIT_FLOAT
%token<value> TK_LIT_FALSE
%token<value> TK_LIT_TRUE
%token TK_ERRO

%type<tree_node> expression
%type<tree_node> expr_or
%type<tree_node> expr_and
%type<tree_node> expr_eq_ne
%type<tree_node> expr_comparisons
%type<tree_node> expr_plus_minus
%type<tree_node> expr_times_div_mod
%type<tree_node> expr_unary
%type<tree_node> expr_parentheses
%type<tree_node> operands

%%

    /* Program generic structure */
program: elements_list | ;
elements_list : elements_list element | element ;
element : variable_declaration ',' | function_declaration ;

    /* Variable declaration */
variable_declaration: type variables_list ;
variables_list: variables_list ';' TK_IDENTIFICADOR | TK_IDENTIFICADOR ;

    /* Function declaration */
function_declaration: function_header function_body ;
function_header: function_parameters TK_OC_OR type '/' TK_IDENTIFICADOR ;
function_parameters: '(' parameters_list ')' | '(' ')' ; 
parameters_list: parameters_list ';' type TK_IDENTIFICADOR | type TK_IDENTIFICADOR ;  
function_body: command_block ;

    /* Commands */
command_block: '{' commands_list '}' | '{' '}' ;
commands_list: commands_list command | command ;
command: 
  command_block ','         /* Recursive block */
| variable_declaration ','
| attribution_command ','
| function_call ','
| return_command ','
| conditional_command ','
| while_command ','
;

    /* Commands: attribution */
attribution_command: TK_IDENTIFICADOR '=' expression ;

    /* Commands: function call */
function_call: TK_IDENTIFICADOR function_arguments  ;
function_arguments: '(' arguments_list ')' | '(' ')' ;
arguments_list: arguments_list ';' expression | expression ;

    /* Commands: return */
return_command: TK_PR_RETURN expression ;

    /* Commands: conditional */
conditional_command: if_command else_command  | if_command  ;  
if_command: TK_PR_IF '(' expression ')' command_block ;
else_command: TK_PR_ELSE command_block ;

    /* Commands: while */
while_command: TK_PR_WHILE '(' expression ')' command_block ;

    /* Expressions */
expression: expr_or                           {$$ = $1;}
;

expr_or: expr_or TK_OC_OR expr_and            {$$ = ast_new_node("|"); ast_add_child($$, $1); ast_add_child($$, $3);}   /* 7: OR  */
| expr_and                                    {$$ = $1;}
;

expr_and: expr_and TK_OC_AND expr_eq_ne       {$$ = ast_new_node("&"); ast_add_child($$, $1); ast_add_child($$, $3);}   /* 6: AND */
| expr_eq_ne                                  {$$ = $1;}
;

expr_eq_ne:
  expr_eq_ne TK_OC_EQ expr_comparisons        {$$ = ast_new_node("=="); ast_add_child($$, $1); ast_add_child($$, $3);}  /* 5: EQUAL     */
| expr_eq_ne TK_OC_NE expr_comparisons        {$$ = ast_new_node("!="); ast_add_child($$, $1); ast_add_child($$, $3);}  /* 5: NOT EQUAL */
| expr_comparisons                            {$$ = $1;}
;

expr_comparisons:
  expr_comparisons TK_OC_GE expr_plus_minus   {$$ = ast_new_node(">="); ast_add_child($$, $1); ast_add_child($$, $3);}  /* 4: GREATER OR EQUAL */
| expr_comparisons TK_OC_LE expr_plus_minus   {$$ = ast_new_node("<="); ast_add_child($$, $1); ast_add_child($$, $3);}  /* 4: LESS OR EQUAL    */
| expr_comparisons '>' expr_plus_minus        {$$ = ast_new_node(">"); ast_add_child($$, $1); ast_add_child($$, $3);}   /* 4: GREATER          */
| expr_comparisons '<' expr_plus_minus        {$$ = ast_new_node("<"); ast_add_child($$, $1); ast_add_child($$, $3);}   /* 4: LESS             */
| expr_plus_minus                             {$$ = $1;}
;

expr_plus_minus:
  expr_plus_minus '+' expr_times_div_mod      {$$ = ast_new_node("+"); ast_add_child($$, $1); ast_add_child($$, $3);}   /* 3  PLUS */
| expr_plus_minus '-' expr_times_div_mod      {$$ = ast_new_node("-"); ast_add_child($$, $1); ast_add_child($$, $3);}   /* 3: PLUS */
| expr_times_div_mod                          {$$ = $1;}
;

expr_times_div_mod:
  expr_times_div_mod '*' expr_unary           {$$ = ast_new_node("*"); ast_add_child($$, $1); ast_add_child($$, $3);}   /* 2: MULTIPLICATION */
| expr_times_div_mod '/' expr_unary           {$$ = ast_new_node("/"); ast_add_child($$, $1); ast_add_child($$, $3);}   /* 2: DIVISION */
| expr_times_div_mod '%' expr_unary           {$$ = ast_new_node("%"); ast_add_child($$, $1); ast_add_child($$, $3);}   /* 2: MODULE */
| expr_unary                                  {$$ = $1;}
;

expr_unary: '-' expr_unary                    {$$ = ast_new_node("-"); ast_add_child($$, $2);}                          /* 1: UNARY MINUS */
| '!' expr_unary                              {$$ = ast_new_node("!"); ast_add_child($$, $2);}                          /* 1: NEGATE      */
| expr_parentheses                            {$$ = $1;}
;

expr_parentheses: '(' expression ')'          {$$ = $2;}                                                                /* 0: PARENTHESES */
| operands                                    {$$ = $1;}
;

operands: 
  TK_IDENTIFICADOR                            {$$ = ast_new_lexeme_node($1);}
| TK_LIT_TRUE                                 {$$ = ast_new_lexeme_node($1);}
| TK_LIT_FALSE                                {$$ = ast_new_lexeme_node($1);}
| TK_LIT_INT                                  {$$ = ast_new_lexeme_node($1);}
| TK_LIT_FLOAT                                {$$ = ast_new_lexeme_node($1);}
| function_call                               {$$ = NULL;}  /* TODO: resolver a árvore da function_call */
;

    /* Primitives types */
type: TK_PR_INT | TK_PR_FLOAT | TK_PR_BOOL ;
%%

#include <stdio.h>

extern int yylineno;
void yyerror (char const *mensagem)
{
    fprintf(stderr, "At line %d: %s\n", yylineno, mensagem);
}