#!/bin/bash

flex tolua.lex && gcc lex.yy.c -o tolua
./tolua $1 $2 > /dev/null
