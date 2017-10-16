#!/bin/sh
\rm `grep -lr uo_art . | grep -v svn | grep .mesh`
