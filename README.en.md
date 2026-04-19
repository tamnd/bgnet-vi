# Beej's Guide to Network Programming &mdash; Vietnamese

> [Tiếng Việt](README.md) &middot; English

Vietnamese translation of [Beej's Guide to Network Programming][bgnet] by
Brian "Beej Jorgensen" Hall. Free to read, free to share, just like the
original.

> Hey! Socket programming got you down? `man` pages not really cutting
> it? You want to write cool Internet programs in C but don't have time
> to wade through a gob of `struct`s?
>
> Well, guess what. Beej already did that nasty business, and now it's
> available in Vietnamese too.

[bgnet]: https://beej.us/guide/bgnet/

## Is this for me?

If you can read Vietnamese and you want to learn how two computers talk
to each other in C, yes. If you'd rather read the English, the [original
guide][bgnet] is right there waiting for you.

If you're a Vietnamese dev who has ever opened `<sys/socket.h>`,
squinted at `struct sockaddr`, and quietly closed the tab, this repo is
for you.

## What you'll learn

Ten chapters, no fluff:

1. Introduction &mdash; what this guide is, who it's for
2. What is a Socket? &mdash; the big picture
3. IP Addresses, `struct`s, and Data Munging &mdash; bytes, endianness,
   `sockaddr`
4. Jumping from IPv4 to IPv6 &mdash; what changed, what didn't
5. System Calls or Bust &mdash; `socket()`, `bind()`, `listen()`,
   `accept()`, `connect()`, `send()`, `recv()`, and friends
6. Client-Server Background &mdash; your first real programs
7. Slightly Advanced Techniques &mdash; `select()`, `poll()`, partial
   `send()`s, serialization, broadcast
8. Common Questions &mdash; the stuff people keep asking Beej
9. Man Pages &mdash; a curated tour
10. More References &mdash; where to go next

## Status

Translation is ongoing, one chapter at a time. Track progress in
[ROADMAP.md](ROADMAP.md) or issue
[#1](https://github.com/tamnd/bgnet-vi/issues/1).

| # | Chapter | Status |
|---|---------|--------|
| 1 | Introduction | ✅ done ([#2](https://github.com/tamnd/bgnet-vi/pull/2)) |
| 2 | What is a Socket? | in review |
| 3 | IP Addresses, structs, and Data Munging | not started |
| 4 | Jumping from IPv4 to IPv6 | not started |
| 5 | System Calls or Bust | not started |
| 6 | Client-Server Background | not started |
| 7 | Slightly Advanced Techniques | not started |
| 8 | Common Questions | not started |
| 9 | Man Pages | not started |
| 10 | More References | not started |

## Repo layout

```
bgnet-vi/
├── src/         # English originals (from upstream, do not edit)
├── src_vi/      # Vietnamese translations (the interesting stuff)
├── source/      # Example C programs (unchanged from upstream)
├── translations/# Other-language builds shipped by upstream
├── website/     # Upstream website assets
├── ROADMAP.md   # Translation plan and progress
├── LICENSE     # CC BY-NC-ND 3.0, same as upstream
└── README.md   # You are here
```

Each translated chapter in `src_vi/` matches a file in `src/` one-to-one
(same filename, same section anchors). That way you can always diff the
two to spot drift.

## How to read

**Online:** the rendered Vietnamese book will land at a TBD URL once
enough chapters are done. Until then, read the markdown directly in
`src_vi/`, GitHub renders it fine.

**Offline:** clone the repo, open any file in `src_vi/` with a markdown
reader. That's it.

**Build the PDF/HTML yourself:** see [Building](#building) below.

## Contributing

Pull requests welcome. A few ground rules so the text stays readable:

- **One chapter per PR.** Don't batch. Small PRs get merged, big PRs
  sit.
- **Translate meaning, not words.** If a literal translation reads like
  a robot wrote it, rewrite it. Beej's tone is casual; yours should be
  too.
- **No machine translation.** Seriously. We can tell. If you don't have
  time to polish, don't submit.
- **Keep code blocks, function names, and `man` page references in
  English.** `bind()` stays `bind()`. `struct sockaddr` stays `struct
  sockaddr`.
- **First use of a technical term:** give the English word first, then
  Vietnamese in parentheses if it helps. Subsequent uses can drop the
  Vietnamese.
- **No em dashes in Vietnamese prose.** Rewrite the sentence or use a
  comma.
- **Section anchors stay intact.** If the English says `{#windows}`,
  the Vietnamese says `{#windows}`.

### Workflow

1. Pick a chapter from the table above that says "not started".
2. Open an issue saying you're taking it, so no one duplicates work.
3. Branch: `translate/<chapter-slug>` (e.g. `translate/socket`).
4. Copy `src/bgnet_part_NNNN_<slug>.md` to `src_vi/` with the same
   filename. Translate in place.
5. Open a PR against `main`. Reference the ROADMAP issue.
6. Expect review. The goal is prose that reads like a Vietnamese
   developer wrote it from scratch, not a translation.

### What reviewers look for

- Does it read naturally out loud?
- Do the jokes still land?
- Are code blocks untouched?
- Are anchor links and image references intact?
- Any machine-translated phrasing sneaking in?

## Building

This repo mirrors the upstream build setup. To produce PDF/HTML
yourself, follow the upstream instructions:

- [Upstream README][upstream-readme] for dependencies (`pandoc`,
  `xelatex`, Liberation fonts)
- [`bgbspd`][bgbspd] build system (clone as a sibling directory)

Then, from the repo root:

```
make all
```

Or via Docker:

```
docker build -t bgnet-vi-builder .
docker run --rm -v "$PWD":/guide -ti bgnet-vi-builder
```

The build targets the English sources in `src/`. A separate
Vietnamese-only target is TODO; until then, swap `src/` for `src_vi/`
locally to build the Vietnamese edition.

[upstream-readme]: https://github.com/beejjorgensen/bgnet/blob/main/README.md
[bgbspd]: https://github.com/beejjorgensen/bgbspd

## Sync with upstream

Upstream commit the translation tracks: `9fb2a78` (beejjorgensen/bgnet,
main branch).

When upstream ships changes, we re-sync `src/` against upstream, then
the diff tells us which translated chapters need touch-ups. If you
notice drift, open an issue.

## Credits

- **Original guide:** Brian "Beej Jorgensen" Hall, 1995-present,
  https://beej.us/guide/bgnet/
- **Vietnamese translation:** Duc-Tam Nguyen (tamnd@liteio.dev) and
  [contributors](https://github.com/tamnd/bgnet-vi/graphs/contributors)

## License

[CC BY-NC-ND 3.0](LICENSE), same as upstream. You can read it, share
it, and translate it. You can't sell it or make derivative works (other
than translations, which upstream explicitly permits). Source code in
the guide is public domain.

Full text: [LICENSE](LICENSE) &middot; [Creative Commons
page](https://creativecommons.org/licenses/by-nc-nd/3.0/).
