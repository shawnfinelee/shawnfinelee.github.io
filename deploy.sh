#!/bin/bash
echo -e "Deploying..."
hugo --environment production
git add .
git status
# read -p "Enter git commit message: " msg
# if [ -z $msg ];then
#   msg="update $(date +'%F %a %T')"
# fi
# git commit -m "$msg"
git commit -m "update blog"
echo -e "Pushing..."
git push
echo -e "View at https://shawnfinelee.github.io"