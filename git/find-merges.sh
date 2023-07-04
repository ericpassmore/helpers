#!/usr/bin/env bash

START=$1

git log "${START}"..HEAD --abbrev-commit --merges --first-parent
