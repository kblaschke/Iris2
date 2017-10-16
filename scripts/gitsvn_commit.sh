#!/bin/bash

git-stash
git-svn dcommit
git-stash apply
git-stash clear

