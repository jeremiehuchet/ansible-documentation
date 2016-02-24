#!/bin/bash

for i in $(cd _ansible ; git tag -l | grep ^v | tac) ; do
   echo "        <div class=\"col-lg-4\">
          <a href=\"$i\" class=\"btn btn-default\" title=\"Ansible $i documentation\">$i</a>
        </div>"
done

