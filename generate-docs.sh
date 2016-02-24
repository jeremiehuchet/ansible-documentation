#!/bin/bash

set -e

basedir=$(cd $(dirname $0) ; pwd)

test -d $basedir/_python || virtualenv $basedir/_python
. $basedir/_python/bin/activate
pip install sphinx

test -d $basedir/_ansible || git clone git@github.com:ansible/ansible.git $basedir/_ansible
(cd $basedir/_ansible ; git fetch origin)

test -d $basedir/_docs || git clone git@github.com:jeremiehuchet/ansible-documentation.git $basedir/_docs
(cd $basedir/_docs ; git fetch origin ; git checkout -f gh-pages)

for tag in $(cd $basedir/_ansible ; git tag -l | grep  -v '^0') ; do
  echo
  echo ">>> $tag"
  echo
  if [ ! -d $basedir/_docs/$tag ] ; then
    (cd $basedir/_ansible/docsite ; make viewdocs)
    cp -r $basedir/_ansible/docsite/htmlout $basedir/_docs/$tag
    cp -r $basedir/_ansible/docsite/_static $basedir/_docs/$tag
    (cd $basedir/_docs ; git add $tag ; git commit -m "Ansible $tag documentation")
  fi
done

(cd $basedir/_docs ; git push origin gh-pages)
