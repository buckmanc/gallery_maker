#!/usr/bin/env bash

delimiter=§

function add_sort_key(){

  data="$(cat)"

  echo "$data" | while read -r path
  do

    dir="$(dirname "$path")"
    filename="$(basename "$path")"

    # get school year designations (1998-1999) to sort at the start of the school year (1998-08-01)
    # standardize dates with and without dashes
    customFileName="$(echo "$filename" | perl -p \
      -e 's/^((\d{4})\-\d{4} )/$2-08-01 $1/g;' \
      -e 's/(?<=\d)[\-_](?=\d)//g'\
      )"

    echo "$dir/$customFileName$delimiter$path"
  done

}

cat | sort -u | add_sort_key | sort -t'/' -k1,1 -k2,2 -k3,3 -k4,4 -k5,5 -k6,6 -k7,7 | perl -pe "s/^.+$delimiter//g"
