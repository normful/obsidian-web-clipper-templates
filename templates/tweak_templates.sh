#!/bin/bash

files=(*.json)

# General modifications for all files (combined to reduce I/O)
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        # The jq command performs multiple transformations on each JSON file in a single pipeline:
        # 1. Set the "path" field to an empty string (saves files to root folder)
        # 2. Modify the "properties" array using |= (update assignment):
        #    - map(if .name == "created" then .name = "date" else . end): Rename "created" properties to "date"
        #    - map(if .name == "date" then .type = "date" else . end): Ensure "date" properties have type "date"
        #    - map(select(.name != "categories")): Remove all properties named "categories"
        # 3. Conditionally append a "title" property to the properties array if it doesn't already exist, with value from noteNameFormat and type "text"
        # 4. Set noteNameFormat to a template string for generating random 8-character filenames
        jq '
.path = "" |
.properties |= (
  map(if .name == "created" then .name = "date" else . end) |
  map(if .name == "date" then .type = "date" else . end) |
  map(select(.name != "categories"))
) |
if (.properties | any(.name == "title")) then . else .properties += [{"name": "title", "value": .noteNameFormat, "type": "text"}] end |
.noteNameFormat = "{{\"A random 8-char string created by randomly picking chars from: abcdefghijklmnopqrstuvwxyz0123456789\"}}"
' "$file" > temp && mv temp "$file"
    fi
done

# Update tags for specific files
jq '.properties |= map(if .name == "tags" then .value = "wikipedia" else . end)' wikipedia-clipper.json > temp && mv temp wikipedia-clipper.json
jq '.properties |= map(if .name == "tags" then .value = "video" else . end)' youtube-clipper.json > temp && mv temp youtube-clipper.json

# Update author value for wikipedia-clipper.json
jq '.properties |= map(if .name == "author" then .value = "Various" else . end)' wikipedia-clipper.json > temp && mv temp wikipedia-clipper.json

# Remove all occurrences of |wikilink
perl -i -pe 's/\|wikilink//g' *.json
