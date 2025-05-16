<!--
make sure you're editing the template, doofus
-->

![banner1](.internals/banners/banner1.png)

# {total} {repo name cap}

A collection of bash scripts (mainly just one though) for creating git-based image galleries that work on Github, Cloudflare Pages, and your own server.

![banner2](.internals/banners/banner2.png)

# Shouldn't this be a proper CLI app written in Python or something?

Yes.

# This is a misuse of git! Git isn't good at binary files!

Also correct.

![banner3](.internals/banners/banner3.png)

# Example Gallery
{table of contents}

![banner4](.internals/banners/banner4.png)

# Nabbing Files Usage

## Nab Individual Images

Long press / right click > save link. Just don't save the thumbnail by mistake!

## One Big Zip File

You can always download everything as [one big zip file]({repo url}/archive/refs/heads/main.zip)

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

