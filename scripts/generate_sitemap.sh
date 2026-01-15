#!/usr/bin/env bash

# based on
# https://github.com/mcmilk/sitemap-generator/blob/master/sitemap.sh

set -e
gitRoot="$(git rev-parse --show-toplevel)"
sitemapPath="$gitRoot/sitemap.xml"
rootUrlPath="$gitRoot/.internals/rooturl.txt"
# values: always hourly daily weekly monthly yearly never
freq="monthly"

if [[ ! -f "$rootUrlPath" ]]
then
  echo "$rootUrlPath is missing"
  echo "cannot generate sitemap"
  exit 0
fi

echo "updating sitemap.xml"

urlRoot="$(cat "$rootUrlPath")"

# begin new sitemap
rm -f "$sitemapPath"

# print head
echo '<?xml version="1.0" encoding="UTF-8"?>' >> "$sitemapPath"
echo '<!-- generator="Gallery Maker Sitemap Generator, https://github.com/buckmanc/gallery_maker/blob/main/scripts/generate_sitemap.sh" -->' >> "$sitemapPath"
echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">' >> "$sitemapPath"

options=()
options+=(\
  ! -iname 'robots.txt' \
  ! -iname 'sitemap.*' \
  ! -iname '.*' \
  ! -iname '*.md' \
  ! -iname '*.json' \
  ! -iname '*.jsonc' \
  ! -iname '*.log' \
  ! -path './css/*' \
  ! -path './js/*' \
  ! -path './img/*' \
  ! -path './tmp/*' \
  ! -path './fonts/*' \
  ! -path './stats/*' \
  ! -path './*test*' \
  ! -path './temp*/*' \
  ! -path './scripts/*' \
  ! -path '*/.internals/*' \
  ! -path './gallery_maker/*' \
  ! -path './.git/*')

# print urls
find . -type f "${options[@]}" -printf "%TY-%Tm-%Td%p\n" | sort | \
while read -r line
do
  modDate="${line:0:10}"
  file="${line:12}"
  file="${file//&/&amp;}"
  url="$urlRoot/$file"
  url="${url//\/index.html/\/}"

  echo "<url>" >> "$sitemapPath"
  echo " <loc>$url</loc>" >> "$sitemapPath"
  echo " <lastmod>$modDate</lastmod>" >> "$sitemapPath"
  echo " <changefreq>$freq</changefreq>" >> "$sitemapPath"
  echo "</url>" >> "$sitemapPath"
done

# print foot
echo "</urlset>" >> "$sitemapPath"

# check syntax with xq
# assuming the right xq is installed
if (type yq > /dev/null 2>&1)
then
  xq . "$sitemapPath" >/dev/null
fi
