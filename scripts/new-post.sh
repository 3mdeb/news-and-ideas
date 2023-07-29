#!/bin/bash

echo "Please provide following information (leave empty field if you are not"
echo "sure or want to fill the field later:"
echo -e "\n- short filename (no date and whitespaces):"
read filename

pattern=" "
while [ -z "$filename" ] || [[ $filename =~ $pattern ]]; do
  echo "filename cannot be empty or containing whitespaces, try again:"
  read filename
done
filename="`date +%Y-%m-%d`-${filename}.md"
filepath="blog/content/post/${filename}"

echo -e "\n- full post title:"
read title

echo -e "\n- author name.surname from the list below (if your full name is not"
echo -e "present in the list, report this to the person responsible for the blog):\n"
ls -1 blog/data/authors | sed -e 's/\.json$//'
echo ""
read author

echo -e "\n- tags (multiple tags should be confirmed by the RETURN key, first"
echo "  empty tag breaks the loop):"
tags_array=()
while : ; do
    ((i++))
    echo -e "tag$i:"
    read tag
    [[ ! -z "$tag" ]] || break
    tag="  - ${tag}"
    tags_array+=("$tag")
done

cp blog/content/post/YYYY-MM-DD-template-post.md $filepath

# replace metadata
if [ ! -z "$title" ]; then
    sed -i "s/title: 'Template post title'/title: ${title}/g" $filepath
fi
if [ ! -z "$author" ]; then
    sed -i "s/author: name.surname/author: ${author}/g" $filepath
fi
sed -i "s/published: false/published: true/g" $filepath
sed -i "s/date: YYYY-MM-DD/date: `date +%Y-%m-%d`/g" $filepath
sed -i "s/archives: \"YYYY\"/archives: \"`date +%Y`\"/g" $filepath
if [ ${#tags_array[@]} -eq 0 ]; then
  echo "Tags array is empty, finishing script"
  exit 0
else
  # remove example tags
  line_nr="$(grep -n '\- tag 1' $filepath | cut -d: -f 1)"
  sed -i "${line_nr}d" $filepath
  line_nr="$(grep -n '\- tag 2' $filepath | cut -d: -f 1)"
  sed -i "${line_nr}d" $filepath
  # add user tags
  line_nr="$(grep -n 'tags:' $filepath | cut -d: -f 1)"
  for i in "${tags_array[@]}"
  do
     ((line_nr++))
     sed -i "${line_nr}i\\${i}" $filepath
  done
fi

echo -e "\nPost template successfully created at:\n${filepath}"
