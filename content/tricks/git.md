---
title: "Git"
date: 2024-06-14T11:41:50+08:00
categories: [ "git" ]
---

记录一些使用git的常用命令和奇技淫巧
- 代理配置
- git忽略文件夹
<!--more-->

## git config proxy 代理配置

``` bash
# HTTP 代理
git config --global http.proxy "http://127.0.0.1:7890"
git config --global https.proxy "http://127.0.0.1:7890"
# socks5 代理
git config --global http.proxy "socks5://127.0.0.1:1081"
git config --global https.proxy "socks5://127.0.0.1:1081"

# 检查设置
git config --global --list | grep proxy
# 取消设置
git config --global --unset http.proxy
git config --global --unset https.proxy

# 只设置github走代理
git config --global http.https://github.com.proxy "http://127.0.0.1:7890"
git config --global https.https://github.com.proxy "http://127.0.0.1:7890"
```


## git忽略文件夹

> 一键生成 .gitignore 的工具 https://www.toptal.com/developers/gitignore

如果一个文件夹(/themes)已经被添加到仓库里，该如何忽略呢？
```bash
# 从暂存区移除文件夹
git rm --cached -r themes
# 将修改添加到工作树
git add .
```
如图能看到，从git暂存区删除的操作，只是结果上删除，这一步骤是作为一次变更被记录在gitlog里的，也就是说如果回溯也是能找到历史的文件的。
![9493bf84635d8dd5ce1425557e6b122c.png](https://raw.githubusercontent.com/shawnfinelee/PubPics/main/uPic/Rjkp99.jpg)

```bash
# 强制推送到远程
git commit -m "remove cached dir"
git push --force origin main
# Done
```


### 真的删除了吗？
远程的仓库里已经看不到我们不需要的文件了，一般情况下这就够了，除了两种特殊情况，
1. 这些文件是敏感文件，需要从远程彻底删除
2. 这些文件很多，会严重影响push/pull项目的速度
如果我去翻commit log，依然可以看到它们。所以还需要彻底删除它

``` bash
# 扫描并重写相关的commit，重写分支的ref
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch themes/ -r' --prune-empty --tag-name-filter cat -- --all
```

![f67035f391468c14201d8ae80978f110.png](https://raw.githubusercontent.com/shawnfinelee/PubPics/main/uPic/UCd6f1.jpg)


```bash
# 干跑，只看效果不会真的操作，相当于自动回滚事务
git push --force --all --dry-run --verbose
# 确认无误后push
git push --force --all --verbose
```
![d300888da7da55c6cc68dd1fdb56a3da.png](https://raw.githubusercontent.com/shawnfinelee/PubPics/main/uPic/g7UnwV.jpg)

过一段时间后确认没有影响，
```bash
git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now
```

### 还有风险吗？
如果别人知道你最初的commit ID，还能看到你的文件。

![20cad591c0d358babb5c495baad4460e.png](https://raw.githubusercontent.com/shawnfinelee/PubPics/main/uPic/2xKcbR.jpg)

确定是敏感文件的话，可以找客服解决。
https://docs.github.com/zh/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository#fully-removing-the-data-from-github
