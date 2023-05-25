#!/usr/bin/env bash
sensors -u > /tmp/raw_sensor.$$.out
readarray -t temp_array < <( grep -iE 'temp1_input|temp2_input' /tmp/raw_sensor.$$.out | head -2 | cut -d":" -f2) 
printf "SYSTEM TEMP ${temp_array[0]} CPU TEMP ${temp_array[1]}"
rm /tmp/raw_sensor.$$.out
