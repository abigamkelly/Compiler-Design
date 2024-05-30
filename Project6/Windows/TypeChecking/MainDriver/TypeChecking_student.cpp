/* PROGRAMMER: Abigail Kelly
 * PROGRAM #: Project 6
 * DUE DATE: Monday, 4/17/23
 * INSTRUCTOR: Dr. Zhijiang Dong
 * This program will detect static semantic errors
 */


#include "Absyn.h"
#include "Semant.h"

using namespace absyn;

Symbol	arg,
		arg2,
		Bool,
		concat,
		cool_abort,
		copy_,
		Int,
		in_int,
		in_string,
		IO,
		isProto,
		length,
		Main,
		main_meth,
		No_class,
		No_type,
		Object,
		out_int,
		out_string,
		prim_slot,
		self,
		SELF_TYPE,
		Str,
		str_field,
		substr,
		type_name,
		val;

void initialize_constants(void)
{
	arg = idtable.add_string("arg");
	arg2 = idtable.add_string("arg2");
	Bool = idtable.add_string("Bool");
	concat = idtable.add_string("concat");
	cool_abort = idtable.add_string("abort");
	copy_ = idtable.add_string("copy");
	Int = idtable.add_string("Int");
	in_int = idtable.add_string("in_int");
	in_string = idtable.add_string("in_string");
	IO = idtable.add_string("IO");
	isProto = idtable.add_string("isProto");
	length = idtable.add_string("length");
	Main = idtable.add_string("Main");
	main_meth = idtable.add_string("main");
	//   _no_class is a symbol that can't be the name of any
	//   user-defined class.
	No_class = idtable.add_string("_no_class");
	No_type = idtable.add_string("_no_type");
	Object = idtable.add_string("Object");
	out_int = idtable.add_string("out_int");
	out_string = idtable.add_string("out_string");
	prim_slot = idtable.add_string("_prim_slot");
	self = idtable.add_string("self");
	SELF_TYPE = idtable.add_string("SELF_TYPE");
	Str = idtable.add_string("String");
	str_field = idtable.add_string("_str_field");
	substr = idtable.add_string("substr");
	type_name = idtable.add_string("type_name");
	val = idtable.add_string("_val");
}

///////////////////////////////////////////////////////////////////////////////
//
//  Type Checking Features
//
//  For each class of expression, there is a tc method to typecheck it.
//  The tc methods make use of the environments previously constructred
//  for each class.  
//  Please implement the following type checking method.
//
//  YOU ARE NOT ALLOWED TO CALL tc_teacher VERSION
///////////////////////////////////////////////////////////////////////////////

void Attr::tc_student(EnvironmentP env)
{	
	/*Attribute declaration format
	  name : type_decl <- init */

	/* if type_decl doesn't exists as a class, report an error */
	InheritanceNodeP type = env->lookup_class(type_decl);
	if (type == NULL) {
		env->semant_error(this) << "Class UndefinedType of attribute " << name << " is undefined." << endl;
	}

	/* if init is provided */
	if (init != NULL) {
		/* Perform type checking on init and save its type info */
		Symbol ti = init->tc(env);
		/* if the type of init is not compatible with type_decl, then report an error */
		if (!env->type_leq(ti, type_decl)) {
			env->semant_error(this) << "Inferred type " << init->getType()
				<< " of initialization of attribute " << name << " does not conform to declared type " 
				<< type_decl << "." << endl;
		}
	}
}


Symbol IntExp::tc_student(EnvironmentP)
{
	type = Int;
	return Int;
}

Symbol BoolExp::tc_student(EnvironmentP)
{
	type = Bool;
	return Bool;
}

Symbol StringExp::tc_student(EnvironmentP)
{
	type = Str;
	return Str;
}

Symbol OpExp::tc_student(EnvironmentP env)
{
	/* OpExp format :
	   left op right */

	/* perform type checking on left and save its return value to ltype
	   perform type checking on right and save its return value to rtype */
	Symbol ltype = left->tc(env);
	Symbol rtype = right->tc(env);
	char opSymbol;

	/* if op is not EQ */
	if (op != EQ) {
		/* if ltype or rtype is not Int, report an error */
		if (ltype != Int || rtype != Int) {
			if (op == PLUS) {
				opSymbol = '+';
			}
			else if (op == MINUS) {
				opSymbol = '-';
			}
			else if (op == MUL) {
				opSymbol = '*';
			}
			else if (op == DIV) {
				opSymbol = '/';
			}
			else if (op == LT) {
				opSymbol = '<';
			}
			else if (op == LE) {
				opSymbol = '<=';
			}
			else if (op == EQ) {
				opSymbol = '=';
			}

			env->semant_error(this) << "Non-Int arguments: " << ltype << " "
				<< opSymbol << " " << rtype << endl;
		}
	}
	else {
		/* if t1 is not the same as t2 and t1 or t2 is Int, Bool, or Str */
		if (ltype != rtype && (ltype == Int || rtype == Int || ltype == Bool 
			|| rtype == Bool || ltype == Str || rtype == Str)) {
			/* report an error */
			env->semant_error(this) << "Illegal comparison with a basic type." << endl;
		}
	}

	/* if op is LT, LE, or EQ */
	if (op == LT || op == LE || op == EQ) {
		/* set attribute type to Bool */
		type = Bool;
	}
	else {
		/* set attribute type to Int */
		type = Int;
	}

	return type;
}


Symbol NotExp::tc_student(EnvironmentP env)
{
	/* NotExp format :
	   NOT expr */

	/* perform type checking on expr and save its return type to t */
	Symbol t = expr->tc(env);

	/* if t is not the same as Bool */
	if (expr->getType() != Bool) {
		/* report an error */
		env->semant_error(this) << "Argument of 'not' has type " 
			<< expr->getType() << " instead of Bool." << endl;
	}

	/* set attribute type to Bool */
	type = Bool;

	return type;
}

Symbol ObjectExp::tc_student(EnvironmentP env)
{
	/* ObjectExp format :
	   name */

	/* if the variable name exists */
	if (env->var_lookup(name) != NULL) {
		/* lookup the variable in symbol table and save its type information 
		   to attribute type */
		type = env->var_lookup(name);
	}
	else {
		/* report an error (undeclared identifier)
			set attribute type to Object */
		env->semant_error(this) << "The variable name doesnt exist in the symbol table" << endl;
		type = Object;
	}
	return type;
}

Symbol NewExp::tc_student(EnvironmentP env)
{
	/* NewExp format :
	   new type_name */
	
	/* lookup the class table to check if the type_name exists if exists */
	if (env->lookup_class(type_name) != NULL) {
		/* set attribute type to type_name*/
		type = type_name;
	}
	else {  
		/* report an error of undefined class */
		env->semant_error(this) << " Class Undefined Type" << endl;
		/* set attribute type to Object */ 
		type = Object;
	}
	return type;
}

Symbol IsvoidExp::tc_student(EnvironmentP env)
{
	/* IsvoidExp format :
		isvoid(expr) */
	
	/* perform type checking on expr */
	Symbol symbol = expr->tc(env);

	/* set attribute type to Bool */
	type = Bool;

	return type;
}

Symbol LetExp::tc_student(EnvironmentP env)
{
	/* LetExp format
	   let identifier : type_decl <- init in body */

	/* lookup type_decl in class table to check if it exists.
	   if it doesn't exist, report an error of undeclared class */
	if (env->lookup_class(type_decl) == NULL) {
		env->semant_error(this) << "Class " << type_decl << " of identifier " <<
			identifier << " is undefined." << endl;
	}

	/* if init is provided */
	if (init != NULL) {
		/* perform type checking on init */
		Symbol type_init = init->tc(env);
		/* if the type of init is not compatible with type_decl
		   report an error of type mismatch */
		if (!env->type_leq(type_init, type_decl)) {
			env->semant_error(this) << "Inferred type " << init->getType() << 
				" of initialization of " << identifier << 
				" does not conform to declared type " << type_decl << "." << endl;
		}
	}

	/* enter a new scope for variables */
	env->var_enterScope();

	/* if identifier is the same as self */
	if (identifier == self) {
		/* report an error */
		env->semant_error(this) << "variableName cannot be self" << endl;
	}
	else {
		/* insert the variable and its type into variable symbol table */
		env->var_add(identifier, type_decl);
	}

	/* perform type checking on body and save the return value to 
	   attribute type */
	type = body->tc(env);

	/* exit the current scope for variables */
	env->var_exitScope();

	return type;
}

Symbol BlockExp::tc_student(EnvironmentP env)
{
	List<Expression>* cur = body;

	/* for each expression in the list */
	while (cur != nullptr) {
		/* perform type checking on the expression 
		and save its return value to attribute type */
		type = (cur->getHead())->tc(env);
		cur = cur->getRest();
	}

	return type;
}


Symbol AssignExp::tc_student(EnvironmentP env)
{
	//Solution given
	
	//AssignExp format:
	//	name <- expr

	//if name is self, report an error
	if (name == self)
		env->semant_error(this) << "Cannot assign to 'self'." << endl;

	//if name is not defined as a variable, report an error
	if (!env->var_lookup(name))
		env->semant_error(this) << "Assignment to undeclared variable " << name
		<< "." << endl;

	//perform type checking on expr and save its return value to attribute type
	type = expr->tc(env);

	//if type of the expression is not compatible with variable type, report an error 
	if (!env->type_leq(type, env->var_lookup(name)))
		env->semant_error(this) << "Type " << type <<
		" of assigned expression does not conform to declared type " <<
		env->var_lookup(name) << " of identifier " << name << "." << endl;

	//return the type of AssignExp
	return type;

}

Symbol CallExp::tc_student(EnvironmentP env)
{
	//No need to implement this method
	return No_type;
}

Symbol StaticCallExp::tc_student(EnvironmentP env)
{
	//No need to implement this method
	return No_type;
}


Symbol IfExp::tc_student(EnvironmentP env)
{
	/* IfExp format :
	   if pred 
       then then_exp
	   else else_exp */

	/* perform type checking on pred, if return value is NOT Bool, report an error */
	if (pred->tc(env) != Bool) {
		/* report an error */
		env->semant_error(this) << "ifExp Predicate is not type Bool." << endl;
	}

	/* perform type checking on then_exp and save the return value, say then_type */
	Symbol then_type = then_exp->tc(env);

	/* perform type checking on else_exp and save the return value, say else_type */
	Symbol else_type = else_exp->tc(env);

	/* set attribute type to the lub of then_type and else_type */
	type = env->type_lub(then_type, else_type);

	return type;
}

Symbol WhileExp::tc_student(EnvironmentP env)
{
	/*WhileExp format :
	  while pred
			body */
	
	/* perform type checking on pred, if return value is NOT Bool, report an error */
	if (pred->tc(env) != Bool) {
		/* report an error */
		env->semant_error(this) << "WhileExp Predicate is not type Bool." << endl;
	}

	/* perform type checking on body */
	body->tc(env);

	/* set attribute type to Object */
	type = Object;

	return Object;
}

Symbol Branch_class::tc_student(EnvironmentP env)
{
	//No need to implement
	return expr->tc(env);
}

Symbol CaseExp::tc_student(EnvironmentP env)
{
	//No need to implement this
	return No_type;
}

void Method::tc_student(EnvironmentP env)
{
	//No need to implement this
}

void Formal_class::tc_student(EnvironmentP env)
{
	//No need to implement this
}

Symbol NoExp::tc_student(EnvironmentP)
{
	type = No_type;
	return No_type;
}