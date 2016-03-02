#!/bin/bash

function startswith() {
  if [ $(echo $1 | grep -c "^$2") -eq 0 ] ; then
    return 1
  else
    return 0
  fi
}

for i in $(cd _docs ; ls -1d v* | tac) ; do
   color="default"
   startswith $i '2.0' && color="success"
   echo "        <div class=\"col-lg-4\">
          <a href=\"$i\" class=\"btn btn-$color\" title=\"Ansible $i documentation\">$i</a>
        </div>"
done

