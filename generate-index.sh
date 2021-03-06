#!/bin/bash

cat - <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Documentation for almost all Ansible versions">
    <meta name="author" content="">

    <title>Documentation for almost all Ansible versions</title>

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">

    <link href="style.css" rel="stylesheet">

    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>

  <body>

    <div class="container">
      <div class="header clearfix">
        <nav>
          <ul class="nav nav-pills pull-right">
            <li role="presentation" class="active"><a href="https://www.ansible.com/">Ansible</a></li>
          </ul>
        </nav>
        <h3 class="text-muted">Ansible documentation</h3>
      </div>

      <div class="jumbotron">
        <h1>Ansible documentation</h1>
        <p class="lead">You're stuck with an older Ansible version? Here is the documentation you need.</p>
      </div>

EOF

for majorMinor in $(find _docs/ -maxdepth 1 -name 'v*' -printf "%f\n" | cut -d '/' -f 2 | sed 's/^v\([0-9]\+\)\.\([0-9]\+\).*$/\1.\2/g' | sort --reverse | uniq) ; do

cat - <<EOF
      <div class="row marketing">
        <div class="col-lg-12">
          <h2>Ansible $majorMinor</h2>
        </div>
EOF

  # mark latest version
  color="success"

  for version in $(find _docs/ -maxdepth 1 -name "v$majorMinor*" -printf "%f\n" | sort --reverse) ; do

cat - <<EOF

        <div class="col-lg-4">
          <a href="$version" class="btn btn-$color" title="Ansible $version documentation">$version</a>
        </div>
EOF

    color="default"

  done

cat - <<EOF

      </div>

EOF

done

cat - <<EOF

      <footer class="footer">
        <p>Hosted on Github Pages</p>
      </footer>

    </div> <!-- /container -->

  </body>
</html>
EOF
