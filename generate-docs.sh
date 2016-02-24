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

for branch in $(cd $basedir/_ansible ; git branch -la | grep '^ *remotes/origin/release' | sed 's/^ *remotes\/origin\///') ; do
  echo
  echo ">>> $branch"
  echo
  version=$(echo $branch | sed 's/^release//')
  if [ ! -d $basedir/_docs/$version ] ; then
    (cd $basedir/_ansible/docsite ; make viewdocs)
    cp -r $basedir/_ansible/docsite/htmlout $basedir/_docs/$version
    (cd $basedir/_docs ; git commit -a -m "Ansible $version documentation")
  fi
done

(cd $basedir/_docs ; git push origin gh-pages)
