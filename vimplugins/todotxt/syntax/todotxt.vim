if exists("b:current_syntax")
    finish
endif

syntax  match  TodoDone      '^[xX]\s.*$'
syntax  match  TodoPriorityA '^([aA])\s'
syntax  match  TodoPriorityB '^([bB])\s'
syntax  match  TodoPriorityC '^([cC])\s'
syntax  match  TodoPriorityD '^([dD])\s'
syntax  match  TodoPriorityE '^([eE])\s'
syntax  match  TodoPriorityF '^([fF])\s'
syntax  match  TodoPriorityG '^([gG])\s'
syntax  match  TodoPriorityH '^([hH])\s'
syntax  match  TodoPriorityI '^([iI])\s'
syntax  match  TodoPriorityJ '^([jJ])\s'
syntax  match  TodoPriorityK '^([kK])\s'
syntax  match  TodoPriorityL '^([lL])\s'
syntax  match  TodoPriorityM '^([mM])\s'
syntax  match  TodoPriorityN '^([nN])\s'
syntax  match  TodoPriorityO '^([oO])\s'
syntax  match  TodoPriorityP '^([pP])\s'
syntax  match  TodoPriorityQ '^([qQ])\s'
syntax  match  TodoPriorityR '^([rR])\s'
syntax  match  TodoPriorityS '^([sS])\s'
syntax  match  TodoPriorityT '^([tT])\s'
syntax  match  TodoPriorityU '^([uU])\s'
syntax  match  TodoPriorityV '^([vV])\s'
syntax  match  TodoPriorityW '^([wW])\s'
syntax  match  TodoPriorityX '^([xX])\s'
syntax  match  TodoPriorityY '^([yY])\s'
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
highlight  default  link  TodoDueDate    Label
highlight  default  link  TodoDate       String
highlight  default  link  TodoProject    Operator
highlight  default  link  TodoContext    Delimiter

let b:current_syntax = "todotxt"

