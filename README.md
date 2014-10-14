
# kumpulaspace.fi site

This site is built on Hakyll, but you do not need to know Hakyll to make even
big changes in the site, as explained in the next section.

## How to modify the site

### Getting Started

Modifying the site *content* is simple:

1. `git clone`
2. Modify files (see subsections for details)
3. `git commit`
4. `git push`

Of course, you can skip the first step if you already have the repository
cloned. Here is an example modification session (you can modify the files in
whatever editor you want):

    git clone h209.it.helsinki.fi:/var/www/ksc
    cd ksc
    $EDITOR content/index-en.markdown # make changes...
    git commit -am "Changed something"
    git push

In the last step the git hooks installed on the server check that your
modifications were sensible, then regenerates the site html. **git push will
fail if you made an error while modifying (for example, messed up markdown
syntax). So watch the output! (and edit, commit and push again if necessary).**

When adding a new page, say, `content/newpage-en.markdown`, you need to
explicitly say you want it included with `git add content/newpage-en.markdown`,
and then commit as normal. Note that multilingual pages are not enforced, and
there is (curretly) no failover in languages that are not supported. so remember
to add the content in all languages you want to support!

Some general notes:

- Almost all content is in content/ subdirectory. All files with the `.markdown`
  extension are rendered with the default layout, and `.pdf`'s are copied as-is.
  All other extensions are ignored.
- Finnish and English pages are given -en and -fi suffixes respectively (e.g.
  index-en.markdown). **Language suffix is mandadory.**

### 1. Modifying existing pages

- You can modify any file under `content/` and its subdirectories.
- Default template in templates/default.html is also modifiable, though it
  should normally not be necessary to modify it. Only if you're 1) adding a new
  language or 2) modifying the top navigation bar.

### 2. Adding new pages

- Add new pages **top-level** pages directly under content-folder:
  Adding a file content/mynewpage-fi.markdown results in /fi/mynewpage.html on
  the site, and so on.
- Add new **projects** under content/projects:
  content/projects/2014-01-01-newproject-fi.markdown results in
  /fi/2014-01-01-newproject.html. *The index in /fi/projects.html is
  automatically updated.*
- Add new publication pdf's under content/publications.

### 3. Adding images

- Add images under `images/`. Then include them (in markdown):
  `![/images/myimage.jpg]`. The first slash is important! Image format doesn't
  matter, though browser support varies with rare formats.

### 4. Layout and style (HTML templates and CSS)

- There is only one html template (`templates/default.html`), which is used to
  render every page.
- All CSS is in css/*.css files
- "interesting" CSS is in css/default.css, typography in css/typebase.css.

# More technical

**Everything below this in this document is relevant only if the executable
needs to be recompiled, or the site installed on a new host.**

The package installs fine with cabal (`cabal install`). However, you will most
likely want to link statically (minimizes server dependencies):

    ghc \
      --make -optl-static -optl-pthread -optl-gssapi \
      -optl-L/home/sim/build/lib \
      site.hs

(Don't worry if there are warnings about some functions possibly failing, we're
not using those.)

The `-optl-L<directory>` is necessary only if your system doesn't come with
static libraries by default. List of required libraries (most are provided by
glibc, except libgmp, so a simple `yum install libgmp-devel` should get you
going):

    libz librt libutil libdl libpthread libgmp libm libffi libc


## Install on a CentOS host

This is for reference only, and probably not 100% correct.

**Packages:**

    yum install httpd git

**Apache:**

    sudo systemctl enable httpd

Create file `/etc/httpd/conf.d/ksc.conf`:

    <Directory "/var/www/html">
        AllowOverride All
    </Directory>

**Site:**

    cd /var/www
    mkdir ksc
    cd ksc
    git clone <ksc-repo> .
    scp <ksc-bin> ./site
    cd /var/www/html
    ln -s ../ksc/_site test

Replace ksc-repo and ksc-bin with the repo url and ksc-bin with the
ghc-generated remote binary.

To test building: `./site clean && ./site build`

**Git hooks:**


