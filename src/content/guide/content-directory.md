---
title: Content directory
description: One markdown file per route, and no page module to go with it.
navLabel: Content Directory
navOrder: 40
---

This page is `src/content/guide/content-directory.md`. No Nix file names it: the
content step read the directory and placed it at `/guide/content-directory/`, and
the nav entry you clicked came from the frontmatter above.

## Path to route

| file                                 | route                      |
| :----------------------------------- | :------------------------- |
| `src/content/overview.md`            | `/overview/`               |
| `src/content/guide/content-directory.md` | `/guide/content-directory/` |
| `src/content/guide/index.md`         | `/guide/`                  |

A nested directory nests the route; a file called `index.md` is the directory's
own page. `.md` is the only extension read, and a name starting with `.` is
skipped.

## Frontmatter is the page declaration

```yaml
---
title: Content directory
description: One markdown file per route.
navOrder: 40
navLabel: Content Directory
showInNav: true
---
```

- `title` — `<title>` and the visible heading. Falls back to the first heading in
  the body, then to a de-slugged file name, so a file with no frontmatter still
  has a name.
- `description` — the `<meta name="description">` tag, omitted when absent.
- `navOrder` — where the entry sits in the derived nav; lower first.
- `navLabel` — the nav text, defaulting to the title.
- `showInNav` — `false` publishes the page without a nav entry.
- `route` — overrides the path-derived route when a page needs somewhere else.

Only those keys are read for the page, and the block is stripped before the
markdown is rendered, so the keys never appear as prose. An unclosed `---` block
fails the build instead of publishing itself.

## Using it from another flake

```nix
content = nixstix.lib.${system}.content;
pages = content.pages {
  dir = ./content;
  site = { title = "my site"; };
  layout = ...;   # optional; receives { page, content, site }
};
```

`layout` wraps the rendered markdown in whatever document you want; the default
one is a page shell with the site title, the derived nav, and the page heading.
