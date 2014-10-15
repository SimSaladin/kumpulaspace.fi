---
title: Projektit
---

# Projektit

$for(projects)$
-  *$title$* ($year$) $if(category)$ $category$ $endif$
    <div style="font-size:80%">
    $if(status)$ - $status$ $endif$
    - Ota yhteyttä: $contact$ (<a href="mailto:$contact_mail$">$contact_mail$</a>)
    - [Lisää tietoa]($url$)
    $if(homepage)$ - Kotisivu: <$homepage$> $endif$
    </div>
$endfor$
