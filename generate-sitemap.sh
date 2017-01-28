#!/bin/bash

date=$1
baseurl=$2

cat - <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>$baseurl</loc>
    <lastmod>$date</lastmod>
    <priority>0.1</priority>
  </url>
EOF

for i in $(cd _docs ; ls -1d v* | tac) ; do

cat - <<EOF
  <url>
    <loc>$baseurl/$i</loc>
    <lastmod>$date</lastmod>
    <changefreq>never</changefreq>
    <priority>0.1</priority>
  </url>
EOF

done

echo '</urlset>'

