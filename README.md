# nixstix

`nixstix` is a small static site generator written in Nix.

It is intentionally narrow:

- author a page as a small Nix AST
- render that AST into HTML
- build a static site directory in `$out`

The project is not trying to become a blog engine, CMS, plugin platform, or JavaScript framework. It is a thin Nix-first tool for producing plain static HTML.

## Architecture

The stable shape is:

- `lib/dsl.nix` — page and node constructors
- `lib/render.nix` — pure HTML rendering
- `lib/site.nix` — static file output builder
- `lib/markdown.nix` — markdown adapter (source in, build-time html out)
- `lib/content.nix` — the content step: a directory of markdown files becomes pages
- `lib/data.nix` — JSON/TOML helpers
- `src/pages/` — authored page definitions
- `src/content/` — pages written as markdown; the path is the route
- `assets/` — copied static assets

The core model stays explicit:

1. Nix AST
2. Renderer
3. Static files in `$out`

## Stable Authoring Surface

This pass treats the following DSL functions as the baseline author-facing API:

- `text`
- `raw`
- `el`
- `attrs`
- `fragment`
- `page`
- `stylesheet`
- `script`
- `markdown`
- `nav`

Example:

```nix
{ dsl, markdown }:

dsl.page {
  title = "Docs";
  route = "docs/index.html";
  head = [ (dsl.stylesheet "/assets/site.css") ];
  body = [
    (dsl.el "main" { class = "page-shell"; } [
      (dsl.el "h1" {} [ (dsl.text "Docs") ])
      (dsl.markdown (markdown.fromFile ../README.md))
    ])
  ];
}
```

## Use It From Another Flake

The library half is a flake output, so a project consumes the same code this
repo builds its own site with:

```nix
{
  inputs.nixstix.url = "github:shaoyanji/Nixstix";
  outputs = { self, nixpkgs, nixstix }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    lib = nixstix.lib.${system};
  in {
    packages.${system}.site =
      lib.site.buildSite {
        name = "my-site";
        pages = [ (import ./site/pages/index.nix { inherit lib; }) ];
        assets = [ ./site/assets ];
      };
  };
}
```

`nix build .#site` writes one store path; serving it is the deploy step, and a
content edit rebuilds only the pages whose markdown changed. Markdown is a build
input of the site, never an eval-time build, so `nix eval` on any page is
sub-second and starts nothing.

Most sites need no page modules at all — `lib.content` turns a directory of
markdown into pages, and `pages` takes those alongside any authored ones:

```nix
pages = lib.content.pages {
  dir = ./content;                 # content/overview.md -> /overview/
  site = { title = "my site"; };   # the default layout's brand
};
```

## Navigation Is Derived

A page writes `(dsl.nav { })` where the nav belongs; the builder fills it from
the pages themselves. Each page declares only its own place in that index:

```nix
page {
  title = "Docs";
  route = "docs/index.html";
  navLabel = "Docs";   # defaults to `title`
  navOrder = 10;       # ascending; ties keep input order
  showInNav = true;    # false keeps the page out of the nav, not out of the site
  ...
}
```

Adding a page puts it in every nav, in order; the current page is marked with
`aria-current="page"`. A hand-typed `<nav>` is the thing this replaces, and
`checks.default-nav` pins the rendered result so it cannot come back.

## Content Directory

A markdown file under `src/content/` is a page, and its path is its route:

| file                                     | route                       |
| :--------------------------------------- | :-------------------------- |
| `src/content/overview.md`                | `/overview/`                |
| `src/content/guide/content-directory.md` | `/guide/content-directory/` |
| `src/content/guide/index.md`             | `/guide/`                   |

The page facts come from a frontmatter block, which is stripped before the
markdown is rendered:

```yaml
---
title: Content directory
description: One markdown file per route.
navLabel: Content Directory
navOrder: 40
showInNav: true
---
```

`title` falls back to the body's first heading and then to the de-slugged file
name, so a file with no frontmatter still has a page title. `route` overrides the
path-derived route when a page needs to live elsewhere. An unclosed `---` block
fails the build rather than publishing its keys as prose.

A page module is still allowed, and `layout` decides how a markdown body sits in
a document — it receives `{ page, content, site }` and the default one is a page
shell with the site title, the derived nav and the page heading. The route and
frontmatter rules are pinned by `checks.content-pure`; the rendered result by
`checks.content-routes`.

## What Ships Today

- a default site build that preserves the README-to-site flow
- a nav index derived from the pages (`dsl.nav`, `navLabel`, `navOrder`, `showInNav`)
- a content directory: `src/content/<route>.md` renders to its route with no page module
- a nested example page migrated from the old HTML experiment
- a static asset copy step for CSS and similar files
- cheap deterministic flake checks for output presence, content markers, internal link resolution and renderer escaping
- `lib.<system>.{site,dsl,render,markdown,content,data}` for other flakes

## Commands

Build the default site:

```sh
nix build .#default
```

Build the README-focused site:

```sh
nix build .#readme
```

Build the HTML experiment:

```sh
nix build .#htmlexp
```

Run validation:

```sh
nix flake check
```

Open a development shell:

```sh
nix develop
```

## Validation Expectations

Now that Nix is part of the working environment, changes should be validated with real Nix commands instead of static inspection alone.

At minimum:

- `nix build .#default`
- `nix build .#readme`
- `nix build .#htmlexp`
- `nix flake check`

The checks are deliberately lightweight. They verify that:

- the default site emits `index.html`
- the nested experiment page exists
- rendered HTML contains expected title/body markers
- every root-relative `href` in the built site names a file that exists (`lib.site.checkLinks`)
- content files land on their routes, and frontmatter never reaches the output
- route derivation and frontmatter parsing hold as pure functions
- escaping and attribute rendering hold on the pure renderer

## Non-goals

`nixstix` is explicitly not doing the following in this product boundary:

- blog engine behavior
- plugin systems
- JavaScript framework integration
- dynamic server behavior
- content management features

## Notes

- `nixpkgs` is pinned to a rev in `flake.nix`. A registry alias (`nixpkgs`) resolves
  through each machine's own channel, so the same input built a different tree per
  host and a consumer could not reproduce a site.
- The old prototype files were moved out of the core product path into `src/legacy/`.
- The implementation favors small pure functions and deterministic build outputs over abstraction breadth.
