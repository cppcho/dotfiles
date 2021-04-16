if exists("b:current_syntax")
    finish
endif

setlocal iskeyword+=40,41,43,45,@-@

syntax  match  TodoDone      '^[xX]\s.*$'
syntax  match  TodoPriorityA '^([aA])\s'
syntax  match  TodoPriorityB '^([bB])\s'
syntax  match  TodoPriorityC '^([cC])\s'
syntax  match  TodoPriorityW '^([wW])\s'
syntax  match  TodoPriorityZ '^([zZ])\s'

syntax  match  TodoDueDate 'due:\d\{2,4\}-\d\{2\}-\d\{2\}' contains=NONE
syntax  match  TodoDate    '\d\{2,4\}-\d\{2\}-\d\{2\}' contains=NONE
syntax  match  TodoProject '\(^\|\W\)+[^[:blank:]]\+'  contains=NONE
syntax  match  TodoContext '\(^\|\W\)@[^[:blank:]]\+'  contains=NONE

" Other priority colours might be defined by the user
highlight  default  link  TodoDone       Comment
highlight  default  link  TodoPriorityA  Label
highlight  default  link  TodoPriorityB  Type
highlight  default  link  TodoPriorityC  Identifier
highlight  default  link  TodoPriorityW  Comment
highlight  default  link  TodoPriorityZ  Comment
highlight  default  link  TodoDueDate    Label
highlight  default  link  TodoDate       String
highlight  default  link  TodoProject    Operator
highlight  default  link  TodoContext    Delimiter

let b:current_syntax = "todotxt"

