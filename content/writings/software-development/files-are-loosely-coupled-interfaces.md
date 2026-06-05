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
**A file can be more than storage. With a stable format, clear metadata,
and readable content, a file becomes a loosely coupled interface between
tools.**

The question that led me here was practical: how does one build an
interoperable ecosystem of personal or communal applications? I was
impressed by Linus Lee's [software
ecosystem](https://github.com/thesephist), so I asked him about the data
structures underneath it. He pointed me to Gordon Brander's article, [If
headers did not exist, it would be necessary to invent
them](https://subconscious.substack.com/p/if-headers-did-not-exist-it-would?s=r).

Linus summarized the idea this way:

{{< quote source="Linus Lee" >}}
The basic idea is that documents and entities are key-value pairs, with
a few "blessed" keys that are universal and an open space for other keys
to become used by specific use cases. I think this is a good way to
reduce coupling between apps and data sources while letting systems
interact.
{{< /quote >}}

That sentence describes a useful architecture pattern. Instead of forcing
every tool to speak to every other tool through bespoke APIs, tools can
coordinate around a shared artifact. The file becomes the interface.
Each application can read the parts it understands and ignore the parts
it does not.

## Metadata Plus Body

The format Gordon recommends is close to the Markdown-plus-front-matter
model used by Hugo: structured metadata at the top, flexible body content
below. That combination is more powerful than either piece alone.

A pure TOML, YAML, or JSON file is easy for software to parse, but it can
become awkward for human expression. A pure Markdown document is easy for
people to write, but it may not provide enough stable structure for
software to coordinate around. Front matter plus body text gives both:
machine-readable fields and human-readable context.

Linus offered a contact-card example:

{{< quote source="Linus Lee" >}}
For example, contact cards may have specific fields for name, phone
number, etc. But maybe in its "body text" field the same info is
mentioned again in a less structured way, so that universal tools that
only know about the "body text" column (like a search engine) can still
make some sense of the entity without having to know about every entity
type in the system.
{{< /quote >}}

That is the important design move. Specialized tools can rely on
specialized fields. General tools can still use the body. The format
does not require every participant to understand the whole schema before
it can provide value.

## Coupling And Ownership

Databases are often the right choice for transactional systems,
concurrent writes, relational queries, access control, and high-volume
operations. I would not replace a billing system or collaborative editor
with a directory of Markdown files. But databases also tend to hide data
behind application-specific interfaces. Once that happens,
interoperability becomes something each application has to explicitly
provide.

Gordon Brander names the integration cost:

{{< quote source="[Gordon Brander](https://subconscious.substack.com/p/composability-with-other-tools?s=r)" >}}
On the web, the most common way to save data is in a database hidden
behind a server. This makes interoperability an explicit feature that
must be implemented through APIs. The default is for web apps not to
interoperate... Rather than implementing each other’s bespoke APIs, apps
can collaborate over a shared file type, cutting down the necessary
integrations from n \* (n-1), to just n.
{{< /quote >}}

That is the architectural advantage of files. A file system creates a
simple ownership model. A user can inspect the data, edit it with a text
editor, version it with Git, sync it with common tools, index it with a
search engine, and transform it with scripts. None of those tools need
permission from the original application.

This is loose coupling in a very concrete form. The producer and consumer
do not need to share a runtime, deployment cadence, language, database,
or API client. They only need enough agreement about the artifact.

## The Schema Still Matters

Files do not remove the need for design. They move the design pressure
into the file format.

If every application invents its own front matter keys, the ecosystem
will drift into a different kind of incompatibility. If the body content
is unstructured but tools depend on fragile text conventions, the format
will become difficult to evolve. If multiple tools write to the same file
without coordination, conflicts and data loss become real risks.

The healthier pattern is to keep a small number of blessed keys stable
and let specialized tools add their own fields without requiring
universal adoption. For example:

```markdown
+++
title = "Jane Doe"
type = "contact"
email = "jane@example.com"
phone = "+1-555-0100"
tags = ["friend", "design"]
+++

Jane is a product designer I met at a local meetup. She is interested in
tools for personal knowledge management and community publishing.
```

A contact manager can read `email` and `phone`. A search tool can index
the body. A static site generator can render the page. A backup tool can
copy the file without knowing anything about contacts. A future tool can
add fields without invalidating the basic document.

## Files And The Web

The IndieWeb adds another useful angle: the web itself is built around
structured documents. HTML is a file format with conventions, links,
metadata, and increasingly rich machine-readable annotations. With
microformats, semantic HTML, feeds, and stable URLs, a rendered web page
can also become an interface.

That matters because the choice is not only "database plus API" or
"local file." A system can expose documents over HTTP in a way that lets
general-purpose tools understand them. In some cases, publishing HTML or
feeds is a better interoperability layer than inventing a JSON API too
early.

Still, for personal tooling, plain files retain an advantage that is hard
to beat: direct ownership. I can open the data in Vim, make a change,
commit it, grep it, sync it, or recover it without waiting for the
application that originally created it.

## When This Pattern Fits

Files-as-interfaces work best when:

1. Human editability matters.
2. The data model is document-shaped.
3. Writes can be serialized or conflict-managed.
4. Tools need to interoperate without sharing a backend.
5. Long-term ownership matters more than centralized control.

They fit poorly when:

1. Many users need concurrent writes.
2. Complex relational queries are central.
3. Strict authorization is required at field or row level.
4. Data volume exceeds what file-oriented tooling can handle cleanly.
5. The system needs transactional guarantees.

That tradeoff is the point. Files are not a universal replacement for
databases or APIs. They are a strong default when the desired property is
composability across small tools and long-lived personal data.

## Conclusion

The appeal of file-based interfaces is not nostalgia for plain text. It
is architectural leverage. A well-designed file format can let many tools
cooperate without turning every integration into a custom API project.

For personal and communal software, that matters. Data should not become
trapped inside each application that touches it. When the artifact is
readable, portable, and stable, the user owns more of the system, and the
software around it can evolve with less coordination cost.

Thanks to Linus Lee for pointing me toward Gordon Brander's article and
for clarifying the value of loosely coupled data sources.
