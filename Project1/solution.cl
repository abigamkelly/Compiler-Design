(* PROGRAMMER: Abigail Kelly
   PROGRAM #: program1
   DUE DATE: Monday, 1/30/23
   INSTRUCTOR: Dr. Zhijiang Dong

   This program will act as a stack.  If the user enters in an integer,
   that integer will be added to the stack.  If the user enters a "+", that
   will also be added to the stack.  If the user enters "d", the contents
   of the stack will be displayed. If the user enters "e", the stack will
   be evaluated (for example, if a "+" is at the top of the stack and 2 integers
   are below it, the 2 integers will be added and the sum will be pushed
   back onto the stack).  If the user enters "x", the program will exit.
*)


(*
   The class A2I provides integer-to-string and string-to-integer
conversion routines.  To use these routines, either inherit them
in the class where needed, have a dummy variable bound to
something of type A2I, or simply write (new A2I).method(argument).
*)
class A2I {
    (*
        c2i converts a 1-character string to an integer.  Aborts
         if the string is not "0" through "9"
    *)
     c2i(char : String) : Int {
	    if char = "0" then 0 else
	    if char = "1" then 1 else
	    if char = "2" then 2 else
        if char = "3" then 3 else
        if char = "4" then 4 else
        if char = "5" then 5 else
        if char = "6" then 6 else
        if char = "7" then 7 else
        if char = "8" then 8 else
        if char = "9" then 9 else
        { abort(); 0; }  -- the 0 is needed to satisfy the typchecker
        fi fi fi fi fi fi fi fi fi fi
     };

(*
   i2c is the inverse of c2i.
*)
    i2c(i : Int) : String {
        if i = 0 then "0" else
        if i = 1 then "1" else
        if i = 2 then "2" else
        if i = 3 then "3" else
        if i = 4 then "4" else
        if i = 5 then "5" else
        if i = 6 then "6" else
        if i = 7 then "7" else
        if i = 8 then "8" else
        if i = 9 then "9" else
	{ abort(); ""; }  -- the "" is needed to satisfy the typchecker
        fi fi fi fi fi fi fi fi fi fi
    };

(*
   a2i converts an ASCII string into an integer.  The empty string 
is converted to 0.  Signed and unsigned strings are handled.  The
method aborts if the string does not represent an integer.  Very
long strings of digits produce strange answers because of arithmetic 
overflow.
*)
    a2i(s : String) : Int {
        if s.length() = 0 then 0 else
	    if s.substr(0,1) = "-" then ~a2i_aux(s.substr(1,s.length()-1)) else
        if s.substr(0,1) = "+" then a2i_aux(s.substr(1,s.length()-1)) else
           a2i_aux(s)
        fi fi fi
     };

(*
  a2i_aux converts the usigned portion of the string.  As a programming
example, this method is written iteratively.
*)
     a2i_aux(s : String) : Int {
	    (let int : Int <- 0 in	
           {	
                (let j : Int <- s.length() in
	                (let i : Int <- 0 in
		                while i < j loop
			            {
			                int <- int * 10 + c2i(s.substr(i,1));
			                i <- i + 1;
			            }
		                pool
		            )
	            );
                int;
	        }
        )
     };

(*
    i2a converts an integer to a string.  Positive and negative 
numbers are handled correctly.  
*)
    i2a(i : Int) : String {
        if i = 0 then "0" else 
        if 0 < i then i2a_aux(i) else
        "-".concat(i2a_aux(i * ~1)) 
        fi fi
    };
	
(*
    i2a_aux is an example using recursion.
*)		
    i2a_aux(i : Int) : String {
        if i = 0 then "" else 
	        (let next : Int <- i / 10 in
		        i2a_aux(next).concat(i2c(i - next * 10))
	        )
        fi
    };
};

Class List inherits IO { 
    (* Since abort() returns Object, we need something of
	type Bool at the end of the block to satisfy the typechecker. 
    This code is unreachable, since abort() halts the program. *)
	isNil() : Bool { { abort(); true; } };

	cons(hd : String) : Cons {
	  (let new_cell : Cons <- new Cons in
	    new_cell.init(hd,self)
	  )
	};

	(* 
	   Since abort "returns" type Object, we have to add
	   an expression of type Int here to satisfy the typechecker.
	   This code is, of course, unreachable.
    *)
	car() : String { { abort(); new String; } };
	cdr() : List { { abort(); new List; } };
	rev() : List { cdr() };
	rcons(i : String) : List { cdr() };
	print_list() : Object { abort() };
};

Class Cons inherits List {
	xcar : String;  -- We keep the car in cdr in attributes.
	xcdr : List; -- Because methods and features must have different names,
		     -- we use xcar and xcdr for the attributes and reserve
		     -- cons and car for the features.

	isNil() : Bool { false };

	init(hd : String, tl : List) : Cons {
	  {
	    xcar <- hd;
	    xcdr <- tl;
	    self;
	  }
	};
	  
	car() : String { xcar };
	cdr() : List { xcdr };
	rev() : List { (xcdr.rev()).rcons(xcar) };
	rcons(i : String) : List { (new Cons).init(xcar, xcdr.rcons(i)) };

	print_list() : Object {
		{
		     out_string(xcar);
		     out_string("\n");
		     xcdr.print_list();
		}
	};
};

Class Nil inherits List {

	isNil() : Bool { true };
    rev() : List { self };
	rcons(i : String) : List { (new Cons).init(i,self) };
	print_list() : Object { true };
};

(* This class is the driver of the program.  It will prompt the user with ">"
   and the user will enter "x", "d", "#" (where # is an integer), or "x". *)
Class Main inherits IO {

	stack : List <- new Nil;    (* List that will operate as a stack *)
    flag : Bool <- true;        (* Flag that controls while loop, if "x" is entered, flag will be made false to stop loop gracefully *)
    intNum1 : Int;              (* Holds top integer in stack after string is converted to int *)
    intNum2 : Int;              (* Holds "second" integer in stack after string is converted to int *)
    total : Int;                (* Holds sum of intNum1 + intNum2 *)

    (* Displays a ">" and takes user input *)
    prompt() : String {
        {
            out_string(">");
            in_string();
        }
    };

    (* main contains a loop that loops until the user enters a "x",
       which will cause the program to exit the loop, which will end the
       program.  There are if statements in the loop to handle specific
       inputs from the user such as "d", "e", "+", and "#" (where # is an
       integer).
    *)
	main() : Object {
        (let z : A2I <- new A2I in                              (* z : A2I is a dummy variable in order to use routines from A2I class *)
         while flag loop                                        (* This loop will stop looping when the user enters "x", which will set flag = false *)
            (let stringNum : String <- prompt() in              (* stringNum : String holds whatever the user inputs *)
            if stringNum = "x" then {                           (* If the user enters "x", set the flag = false *)
                flag <- false;
                out_string("COOL program successfully executed.\n");
            }
            else {                                              (* If user does not enter "x", continue with program *)
                stack <- (new Cons).init(stringNum, stack);     (* Add element to stack *)
                if stringNum = "e" then {                       (* If the user enters "e" evaluate the operations in the stack *)
                    stack <- stack.cdr();                       (* Remove "e" from top of stack so what's below can be evaluated *)
                    if stack.car() = "+" then {                 (* If the top of the stack is "+", then evaluate addition of two integers below it on stack *)
                        stack <- stack.cdr();
                        stringNum <- stack.car();
                        if stringNum.length() < 2 then {        (* If top string is one character, convert character to integer *)
                            intNum1 <- z.c2i(stack.car());
                            stack <- stack.cdr();
                            stringNum <- stack.car();
                            if stringNum.length() < 2 then {    (* If second string is one character, convert character to integer *)
                                intNum2 <- z.c2i(stack.car());
                                stack <- stack.cdr();
                            }
                            else {                              (* If second string is greater than one character,  convert string to integer *)
                                intNum2 <- z.a2i(stack.car());
                                stack <- stack.cdr();
                            }
                            fi;
                        }
                        else {                                  (* If top string is greater than one character, convert string to integer *)
                            intNum1 <- z.a2i(stack.car());
                            stack <- stack.cdr();
                            stringNum <- stack.car();
                            if stringNum.length() < 2 then {    (* If second string is one character, convert character to integer *)
                                intNum2 <- z.c2i(stack.car());
                                stack <- stack.cdr();
                            }
                            else {                              (* If second string is greater than one character, convert string to integer *)
                                intNum2 <- z.a2i(stack.car());
                                stack <- stack.cdr();
                            }
                            fi;
                        }
                        fi;
                        total <- intNum1 + intNum2;             (* Calculate the sum of the two integers *)
                        stack <- (new Cons).init(z.i2a(total), stack);      (* Push the string of the sum onto the stack *)
                    }      
                    else 0                                      (* Do nothing *)
                    fi;
                }
                else {
                    if stringNum = "d" then {                   (* If user enters "d" then display the contents of the stack *)
                        stack <- stack.cdr();                   (* Remove "d" from the stack *)
                        stack.print_list();                     (* Display *)
                    }
                    else 0                                      (* Do nothing *)
                    fi;
                }
                fi;
            }
            fi
            )
        pool
        )
	};
};			    