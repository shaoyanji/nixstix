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
- `lib/markdown.nix` — markdown adapter
- `lib/data.nix` — JSON/TOML helpers
- `src/pages/` — page definitions
- `src/content/` — markdown or other content inputs
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

## What Ships Today

- a default site build that preserves the README-to-site flow
- a nested example page migrated from the old HTML experiment
- a static asset copy step for CSS and similar files
- cheap deterministic flake checks for output presence and content markers

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

## Non-goals

`nixstix` is explicitly not doing the following in this product boundary:

- blog engine behavior
- plugin systems
- JavaScript framework integration
- dynamic server behavior
- content management features

## Notes

- The old prototype files were moved out of the core product path into `src/legacy/`.
- The implementation favors small pure functions and deterministic build outputs over abstraction breadth.
