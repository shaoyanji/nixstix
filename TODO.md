# Handoff

## Where it stands

`nixstix` is a thin Nix-first static site generator: a DSL (`lib/dsl.nix`), a
pure renderer (`lib/render.nix`), a site builder (`lib/site.nix`), a markdown
adapter (`lib/markdown.nix`) and data helpers (`lib/data.nix`).

Packages: `default`, `readme`, `htmlexp`. Library output: `lib.<system>.{site,
dsl, render, markdown, data}`.

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
- **Checks assert structure, not prose.** `checks.default-links` walks every
  built `href="/…"` and fails on one that names no file; `render-escape` pins
  escaping and attribute rendering. The old marker greps stay as smoke tests.

## Next steps, in order

1. A route index: collect `page.route` once and expose it to pages, so a nav is
   derived from the pages that exist rather than typed by hand.
2. A `site` app (`apps.<system>.<host>`) that serves a built site from the store
   over loopback — the same artifact production serves, no second copy.
3. Only then: a content directory convention (`src/content/<route>.md` renders to
   the matching route) so a docs tree needs no per-page Nix file.

Keep the boundary: not a CMS, blog engine, plugin platform, JS framework or
dynamic server.

## Validation

Every pass ends with real commands:

```sh
nix build .#default && nix build .#readme && nix build .#htmlexp && nix flake check
```
