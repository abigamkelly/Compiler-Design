/* PROGRAMMER: Abigail Kelly
 * PROGRAM #: Project 5
 * DUE DATE: Wednesday, 4/5/23
 * INSTRUCTOR: Dr. Zhijiang Dong
 */


#include <algorithm>
#include "slp.h"


using namespace std;

/* To be implemented by stduents */
void CompoundStm::interp( SymbolTable& symbols )
{
	stm1->interp(symbols);		/* evalue first statement */
	stm2->interp(symbols);		/* evaluate second statement */
}


/* To be implemented by stduents */
void AssignStm::interp( SymbolTable& symbols )
{
	symbols[id] = exp->interp(symbols);	/* evaluate expression and update value
										   in symbol table */
}


void PrintStm::interp( SymbolTable& symbols )
{
	exps->interp(symbols);
}


int IdExp::interp( SymbolTable& symbols )
{
	/* look up in table */
	return symbols[id];
}


int NumExp::interp( SymbolTable& symbols )
{
	/*return the constant (check definition of NumExp class) */
	return num;
}


int OpExp::interp( SymbolTable& symbols )
{
	/* call interp for left and right operand,
	based on type of operand, perform operation
	and return final result */

	int l = left->interp(symbols);		/* evaluate the left expression */
	int r = right->interp(symbols);     /* evaluate the right expression */

	/* choose operation */
	switch (oper)
	{
	case PLUS:
		return l + r;
	case MINUS:
		return l - r;
	case TIMES:
		return l * r;
	case DIV:
		return l / r;
	}
}

int EseqExp::interp( SymbolTable& symbols )
{
	/* evaluate statment first, then evaluate the
	expression and return the result of the
	expression */
	stm->interp(symbols);
	return exp->interp(symbols);
}


void PairExpList::interp( SymbolTable& symbols)
{
	/* related to interp to printstm interp */
	cout << head->interp(symbols) << " ";
	tail->interp(symbols);			/* evaluate the tail */
}


void LastExpList::interp( SymbolTable& symbols)
{
	cout << head->interp(symbols) << endl;
}