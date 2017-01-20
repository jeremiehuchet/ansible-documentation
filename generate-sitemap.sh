#!/bin/bash

date=$1
baseurl=$2

echo '<?xml version="1.0" encoding="UTF-8"?>'
echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'

for i in $(cd _docs ; ls -1d v* | tac) ; do
  echo '  <url>'
  echo "    <loc>$baseurl/$i</loc>"
  echo "    <lastmod>$date</lastmod>"
  echo '    <changefreq>never</changefreq>'
  echo '    <priority>0.1</priority>'
  echo '  </url>'
done

echo '</urlset>'

