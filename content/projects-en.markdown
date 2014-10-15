---
title: Projects
---

# Projects


$for(projects)$
-  *$title$* ($year$) $if(category)$ $category$ $endif$
    <div style="font-size:80%">
    $if(status)$ - $status$ $endif$
    - Contact: $contact$ (<a href="mailto:$contact_mail$">$contact_mail$</a>)
    - [More info]($url$)
    $if(homepage)$ - Homepage: <$homepage$> $endif$
    </div>
$endfor$
