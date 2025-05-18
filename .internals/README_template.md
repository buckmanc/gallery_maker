<!--
make sure you're editing the template, doofus
-->

![banner1](.internals/banners/banner1.png)

# {repo name cap}

A collection of bash scripts (mainly just one though) for creating git-based image galleries that work on Github, Cloudflare Pages, and your own server. Originally designed for managing wallpaper collections, then expanded for personal photo and video archives.

![banner2](.internals/banners/banner2.png)

# How To Use

```bash
git init
git submodule add github.com/buckmanc/gallery_maker
# add your pictures in sub dirs
./gallery_maker/make_gallery.sh
git add . && git commit -m "built gallery"
git push
profit
```

# Hosting

This project has built-in support for [Cloudflare Pages](https://pages.cloudflare.com/). Start a Page, attach your repo, and use the raw HTML format. Their max individual file size limit is 25MB and their max file count is 20,000, but you can use the [update_cloudflare_branch.sh](/repo_scripts/update_cloudflare_branch.sh) script to create a branch with only the thumbnails and html files which link to the original images in your public Github repo.

![banner4](.internals/banners/banner4.png)

# Theoretical Complaints

## Shouldn't this be a proper CLI app written in Python or something?

Yes.

## This is a misuse of git! Git isn't good at binary files!

Also correct.

## This dumps so many thumbnails onto the page at once! My browser takes forever to load it! You should be doing some kind of scrolly-scrolly magic!

You're not wrong.

![banner4](.internals/banners/banner4.png)

# Example Gallery
{table of contents}

![banner5](.internals/banners/banner5.png)

# Nabbing Files

## Nab Individual Images

Long press / right click > save link. Just don't save the thumbnail by mistake!

## One Big Zip File

You can always download everything as [one big zip file]({repo url}/archive/refs/heads/main.zip)

## Regular Clone

If you're a Git user and you have no storage concerns, just clone the whole thing.

## Shallow Clone

If using Git, I recommend making a shallow clone of this repo to pull only the current images and not the full history. A shallow [update script](update.sh) is included for ease of use and scheduling.

To make a simple shallow clone:
```shell
git clone --rescurse-submodules --depth 1 {repo url}
```

Or to clone only the directories you want in a shallow fashion (for example, to ignore the {mobile size} mobile folder):
```shell
# shallow clone but download and checkout bupkis
git clone --filter=blob:none --no-checkout --recurse-submodules --shallow-submodules --depth 1 {repo url}

# set git to only clone these folders
git sparse-checkout set ./desktop ./terminal ./gallery_maker

# download and checkout
git checkout main

```

