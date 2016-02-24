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

for tag in $(cd $basedir/_ansible ; git tag -l | grep  -v '^0' | grep -v '^v0' | grep -v '^v1.0' | grep -v '^v1.1' | grep -v '^v1.2' | grep -v '^v1.3') ; do
  echo
  echo ">>> $tag"
  echo
  (cd $basedir/_ansible ; git checkout -f $tag ; git clean -f)
  sed -i "s/html_short_title =.*$/html_short_title = 'Ansible $tag'/g" $basedir/_ansible/docsite/conf.py
  sed -i "s/html_title =.*$/html_title = 'Ansible $tag Documentation'/g" $basedir/_ansible/docsite/conf.py
  test -f $basedir/_ansible/docsite/_themes/srtd/layout.html && sed -i "s/Documentation/Documentation $tag/g" $basedir/_ansible/docsite/_themes/srtd/layout.html
  test -d $basedir/_docs/$tag && rm -rf $basedir/_docs/$tag
  (cd $basedir/_ansible/docsite ; make viewdocs)
  cp -r $basedir/_ansible/docsite/htmlout $basedir/_docs/$tag
  cp -r $basedir/_ansible/docsite/_static $basedir/_docs/$tag
  (cd $basedir/_docs ; git add $tag ; git commit -m "Ansible $tag documentation")
done

(cd $basedir/_docs ; git push origin gh-pages)
