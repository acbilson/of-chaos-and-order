+++
title = 'Files are loosely coupled interfaces'
date = 2022-03-16
draft = false
lastmod = 2022-10-05
eyebrow = 'Essay'
subjects = ['Software Development']
tags = ['interoperability', 'file', 'interface', 'markdown', 'api']
aliases = ['/plants/technology/files-are-loosely-coupled-interfaces/']
+++
How does one build an interoperable ecosystem of personal (or communal)
applications? Impressed by Linus Lee’s [enormous
ecosystem](https://github.com/thesephist), I emailed him with my own
questions about underlying data structures. He pointed me to an
invaluable article by Gordon Brander, [if headers did not exist, it
would be necessary to invent
them](https://subconscious.substack.com/p/if-headers-did-not-exist-it-would?s=r).
Linus summarizes:

{{< quote source="Linus Lee" >}}
The basic idea is that documents and entities are key-value pairs, with
a few "blessed" keys that are universal and an open space for other keys
to become used by specific use cases. I think this is a good way to
reduce coupling between apps and data sources while letting systems
interact.
{{< /quote >}}

The file format Gordon recommends is quite similar to Hugo’s Markdown
with header metadata. So similar, in fact, that there’s little reason
not to use the same format. While I could opt for only a TOML/YAML file,
the body text grants powerful variability. Later in Linus' email he
writes:

{{< quote source="Linus Lee" >}}
For example, contact cards may have specific fields for name, phone
number, etc. But maybe in its "body text" field the same info is
mentioned again in a less structured way, so that universal tools that
only know about the "body text" column (like a search engine) can still
make some sense of the entity without having to know about every entity
type in the system.
{{< /quote >}}

I do appreciate the structure of a backend SQLite table, and a
JSON-formatted column can accomplish nearly the same result as a header,
but nothing beats the convenience of opening a plain-text file and
making edits in Vim. As Gordon notes, the structure of a database
naturally results in a plethora of bespoke APIs that get increasingly
difficult to manage.

{{< quote source="[Gordon Brander](https://subconscious.substack.com/p/composability-with-other-tools?s=r)" >}}
On the web, the most common way to save data is in a database hidden
behind a server. This makes interoperability an explicit feature that
must be implemented through APIs. The default is for web apps not to
interoperate... Rather than implementing each other’s bespoke APIs, apps
can collaborate over a shared file type, cutting down the necessary
integrations from n \* (n-1), to just n.
{{< /quote >}}

There is one piece that the IndieWeb movement adds to this concept that
I think is worth further exploration. While everything Gordon says about
file format interoperability is true, and a database with an API layer
does not enable the same degree of interoperability, the web itself is
in a structured file format: HTML. With a bit of attention to shared
conventions, a web page itself can supply a flexible interface with
equal interoperability to a file format. If a tool renders HTML instead
of a JSON API, many tools can read and understand the files returned
from the web server. However, since one of my values is the ability to
edit my data in a text editor, a regular file format still wins out over
a database.

Thanks so much to Linus for the link to Gordon’s article and the insight
about loosely-coupled data sources!
