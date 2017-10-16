#!/bin/bash

git-stash
git-svn rebase
git-stash apply
git-stash clear

