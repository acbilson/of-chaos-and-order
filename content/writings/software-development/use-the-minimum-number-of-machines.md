+++
title = 'Use the minimum number of machines'
date = 2022-01-28
draft = false
lastmod = 2023-04-06
eyebrow = 'Essay'
subjects = ['Software Development']
tags = ['architecture', 'efficiency', 'scalability', 'kubernetes']
aliases = ['/plants/technology/use-the-minimum-number-of-machines/']
+++
Whether hosting a personal web service or launching entrepreneurial
software, use the least number of machines to achieve your goal.

Because of the prevalence of cluster software like Kubernetes, you may
conclude that the way of the future for any software is to run inside a
geographically dispersed, distributed set of Kubernetes clusters. Talk
of the power of microservices and the incredible feats of engineering
that Google, Facebook, and Amazon have achieved with these power tools
builds a lot of FOMO in our industry. But you must resist the urge.

First, you don’t *really* understand Kubernetes. You may think it’s a
suped-up version of container orchestration, but it’s actually “a
general-purpose cluster operating system kernel”
([ButtonDown](https://buttondown.email/nelhage/archive/two-reasons-kubernetes-is-so-complex/)).
For what a cluster OS can achieve, it’s unmatched, but you almost
certainly don’t need a cluster OS right now. Probably never.

Second, you underestimate the power of an individual computer. Computers
at scale can do crazy stuff, but a single computer, with a little
attention to maximize resource usage, can too. Expanding the number of
available machines can gloss over poor design choices for a long time
and burn a hole in your pocketbook. [David
Crawshaw](https://crawshaw.io/blog/one-process-programming-notes) notes
how a few performance adjustments can enable your startup software to
manage many thousands of requests per second on a single mid-size Cloud
VM.

Third, you overly respect how well large companies actually utilize
their distributed compute. The mass distribution of a service does
nothing for it’s optimization without careful thought down to the
system-level calls. Realistically, most big companies just throw money
at the problem instead of digging that deep into their services. A paper
by Frank McSherry, Michael Isard and Derek G. Murray explores the cost
of scalability, leading their introduction with this quote:

{{< quote source="[Paul Barham](https://www.usenix.org/system/files/conference/hotos15/hotos15-paper-mcsherry.pdf)" >}}
You can have a second computer once you’ve shown you know how to use the
first one.
{{< /quote >}}

## Caveat

Valeriano Manassero raises an excellent caveat to the the number of
machines you’ll need for your project. What about redundancy and
service-level agreements (SLAs)?

{{< quote source="[Valeriano Manassero](https://indieweb.social/@vmanassero@mastodon.online/110150335148727840)" >}}
@acbilson while I agree many applications don’t need a lot of compute
power, almost every business project have specific SLA that can be
guaranteed with, at least, two different set of nodes that may have also
their specific requirements. I’m not saying you are wrong but just
missing a topic usually discussed a lot during infrastructure design.
{{< /quote >}}

Many things can go wrong with your service. You will need to bring it
down to apply security patches and upgrades. You could make an update
that renders it inaccessible until you’ve fixed it, or at least rolled
your service back. And that’s in your control; then there’s external
threats like denial of service (DOS). If the folks using your service
are disrupted by these events that will reflect poorly upon you; it
might even breach your contract.

Some kinds of redundancy can be supplied at a machine-level, like
running multiple copies of your service. However, machine-level
disruptions can only be prevented with machine-level solutions. If your
service can be down for a few minutes, running a replica and using a DNS
fail-over might be sufficient. If you need more, well, now you’re
looking at larger infrastructure needs.
