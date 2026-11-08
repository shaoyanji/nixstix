# Handoff

## Where it stands

`nixstix` is a thin Nix-first static site generator: a DSL (`lib/dsl.nix`), a
pure renderer (`lib/render.nix`), a site builder (`lib/site.nix`), a markdown
adapter (`lib/markdown.nix`) and data helpers (`lib/data.nix`).

Packages: `default`, `readme`, `htmlexp`. Library output: `lib.<system>.{site,
dsl, render, markdown, content, data}`.

## What this pass changed

- **No import-from-derivation.** `markdown.fromFile` used to read a `runCommand`
  during evaluation, so evaluating any page started a cmark build. A page now
  renders as ordered string/file segments and the builder `cat`s the markdown
  html as a build input: `nix eval .#packages.<system>.default.drvPath` is ~1 s
  and builds nothing, and an edit rebuilds only the pages whose content changed.
- **`nixpkgs` is pinned to a rev.** `nixpkgs.url = "nixpkgs"` was a registry
  alias; it resolved through the consumer's channel, so the same input produced a
  different tree per host.
- **The library is a flake output**, so another project builds its site with
  `inputs.nixstix.lib.${system}.site.buildSite` instead of importing four files
  by relative path.
- **Navigation is derived.** `dsl.nav` is a slot the builder fills from the
  pages; ordering, labels and `aria-current` come from the index, so adding a
  page updates every nav.
- **Checks assert structure, not prose.** `checks.default-links` walks every
  built `href="/…"` and fails on one that names no file; `default-nav` pins the
  derived nav; `render-escape` pins escaping and attribute rendering. The old
  marker greps stay as smoke tests.

## Next steps, in order

1. ~~A route index~~ — done: `dsl.nav` is a slot the builder fills from
   `page.route` / `navLabel` / `navOrder` / `showInNav`, and `checks.default-nav`
   pins the order, the labels and the current-page marker.
2. ~~A serve app~~ — done: `apps.default` is `python3 -m http.server` bound to
   127.0.0.1 against the built site's store path (`PORT` overrides 8000), so
   `nix run` serves the artifact Pages gets rather than a second copy.
3. ~~A content directory convention~~ — done: `lib/content.nix` reads
   `src/content/**/*.md`, derives each route from the path, takes title,
   description and nav placement from a frontmatter block, and renders the body
   through the same markdown step. `checks.content-pure` pins the route and
   frontmatter rules; `checks.content-routes` pins the built pages.

Keep the boundary: not a CMS, blog engine, plugin platform, JS framework or
dynamic server.

## Validation

Every pass ends with real commands:

```sh
nix build .#default && nix build .#readme && nix build .#htmlexp && nix flake check
```
