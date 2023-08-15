#!/usr/bin/env bash

for i in 1421 1422 1423 1426 1427 1429 1430 1431 1441
do
  gh issue view $i >> ~/issues-to-migrate.txt
done
