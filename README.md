
# www.kumpulaspace.fi

This site is built on Hakyll, but you do not need to know Hakyll to make even
big changes in the site, as explained in the next section.

## Modifying the content

This section assumes knowing the very basics of version control (git).

In short, the site is updated by the modifying files (under the
`content`-directory) in this repo, `git commit`ing and `git push`ing to the
server. Git hooks installed on the server takes care of the rest.

Here is an example modification session, using `$EDITOR` to make changes (you
can modify the files in whatever editor or file browser you want):

    git clone h209.it.helsinki.fi:/var/www/ksc
    cd ksc
    git checkout master
    $EDITOR content/index-en.markdown # make changes...
    git commit -am "Changed something"

    # To /test
    git push

    # To production
    git push origin master:production


*To avoid unnecessary headaches, always work with the master branch checked out
locally.* Pushing to the master branch *always* modifies only the /test section
of the site - to update the production instance, refer to the section "To
production" below.

In the last step the git hooks installed on the server check that your
modifications were sensible, then regenerates the site html. **git push will
fail if you made an error while modifying (for example, messed up markdown
syntax). So watch the output!** Edit, commit and push again if necessary.

When adding a new page, say, `content/newpage-en.markdown`, you need to
explicitly say you want it included with `git add content/newpage-en.markdown`,
and then commit as normal. Note that multilingual pages are not enforced, and
there is (curretly) no failover in languages that are not supported. so remember
to **add the content in all languages you want to support!**

Things to remember:

- Almost all content is in `content` subdirectory. Files with the `.markdown`
  extension are rendered with the default layout, and `.pdf`'s are copied as-is.
  All other extensions are ignored.
- Finnish and English pages are given `-en` and `-fi` suffixes respectively (e.g.
  `content/index-en.markdown`). **The language suffix is mandadory.**

### 1. Modifying existing pages

- Modify any file under `content/` and its subdirectories.
- Default template in templates/default.html is also easily modifiable, though it
  should normally not be necessary to modify it. Only if you're
  1. Adding a new language, or
  2. modifying the top navigation bar.

### 2. Adding new pages

- New **top-level** page directly under content-folder:
  Adding a file content/mynewpage-fi.markdown results in a
  `http://.../fi/mynewpage.html` page on the site, and so on.
- New **projects** under `content/projects`:
  `content/projects/2014-01-01-newproject-fi.markdown` results in
  `/fi/2014-01-01-newproject.html`. *The index in `/<lang>/projects.html` is
  automatically updated.*
    
  New project template (place in
  `content/projects/YYYY-MM-DD-sometitle-fi.markdown` and
  `content/projects/YYYY-MM-DD-sometitle-en.markdown`)

        ----
        title: Some project
        contact: Contact Person
        contact_mail: contact.person@mail.com
        homepage: http://example.com
        category:
        status:
        ----

        Project description here.

- New **publication pdf's** just add them under content/publications (with the
  .pdf ext.), `git add`, commit and push.

- Similarily to projects, add new **course or thesis descriptions** under
  `courses/undergrad/` or `courses/postgrad/`. The respective indexes and tags
  are updated automatically.

**Tags:** project, course and thesis pages are parsed for the special meta-field
`tags:` in the top section of the file. A page is generated for each tag on the
respective section of the site (see the course, thesis and course listing pages
on the generated site). Tags are separated by commas, so that a file with `tags:
HY Physics, Basic` is tagged under both `HY Physics` and `Basic`.

### 3. Adding images

- Add images under `images/`. Then include them (in markdown):
  `![/images/myimage.jpg]`. The first slash is important! Image format doesn't
  matter, though browser support varies with rare formats.

### 4. Layout and style (HTML templates and CSS)

- There is only one html template (`templates/default.html`), which is used to
  render every page.
- All CSS is in css/*.css files
- "interesting" CSS is in css/default.css, typography in css/typebase.css.

## To production

So, you have done changes and all looks good in the testing
(`http://../test/...`) section? Good. Now you just need to publish the updated
content to production.

To publish, you just need to push into the *remote* branch *production*.
This is as simple as `git push origin master:production`. And you are done, the
site is now deployed!

# More technical

**Everything below this in this document is relevant only if the executable
needs to be recompiled (to add some cool new meta features), or the site
installed on a new host.**

To install from source, you will need a working, fairly recent versions of ghc
and cabal-install installed. Then just clone the repo, and run `cabal install`
at the root of the repo.

For deploying it is advised to link the binary statically. This minimises
dependencies on the server versus dynamically linked binary:

    ghc \
      --make -optl-static -optl-pthread -optl-gssapi \
      -optl-L/home/sim/build/lib \
      site.hs

(Don't worry if there are warnings about some functions possibly failing, we're
not using those.)

The `-optl-L<directory>` is necessary only if your system doesn't come with
static libraries by default. This is a list of required libraries (most are
provided by glibc, except libgmp, so a simple `yum install libgmp-devel` should
get you going):

    libz librt libutil libdl libpthread libgmp libm libffi libc


## Install on a CentOS (6) host

This is for reference only, and probably not 100% complete walkthrough.

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
    git checkout -b test
    ln -s ../../githooks/{post,pre}-receive .git/hooks/
    scp <ksc-bin> ./site
    cd /var/www/html
    ln -s ../ksc/_site test       # _site dir is used by `./site build`

Replace ksc-repo and ksc-bin with the repo url and ksc-bin with the
ghc-generated remote binary.

To test building, on the server run `./site clean && ./site build`.

**Git hooks:**


