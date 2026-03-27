HANDOFF PACKET FOR NEXT SESSION

Project: shaoyanji/nixstix
Mode: thin continuation pass
Intent: continue from the now-validated refactor without reopening architecture or widening scope

Current status

nixstix has been refactored from a prototype-shaped repo into a thin static-site generator with a clear split:

- DSL: `lib/dsl.nix`
- Renderer: `lib/render.nix`
- Site builder: `lib/site.nix`
- Markdown adapter: `lib/markdown.nix`
- Data helpers: `lib/data.nix`

The public flake/package surface is trimmed to real outputs only:
- `default`
- `readme`
- `htmlexp`

The README-to-site path is preserved.
The old HTML experiment is preserved, but rebuilt on the shared layer.
Legacy prototype files were moved out of the core product path into `src/legacy/`.

Environment note

Nix is installed in the environment now.
Do not treat validation as hypothetical.
Any implementation pass must end with real Nix build/check validation.

Validated state

The current staged tree has already been validated successfully with:

- `nix build .#default`
- `nix build .#readme`
- `nix build .#htmlexp`
- `nix flake check`

All succeeded.

Validated output inspection:
- default output contains:
  - `index.html`
  - `experiments/htmlexpv1/index.html`
  - `assets/site.css`
- readme output contains:
  - `index.html`
  - `assets/site.css`
- htmlexp output contains:
  - `experiments/htmlexpv1/index.html`
  - `assets/site.css`

Known fixes already made during validation

Only minimal fixes were needed:
- two recursive-scope bugs in the new library layer
- one stale README content marker in `flake.nix` checks

Those fixes are already accounted for in the staged tree.

Files in the current refactor

Core product files:
- `README.md`
- `flake.nix`
- `flake.lock`
- `default.nix`
- `shell.nix`
- `lib/dsl.nix`
- `lib/render.nix`
- `lib/site.nix`
- `lib/markdown.nix`
- `lib/data.nix`
- `assets/site.css`
- `src/pages/index.nix`
- `src/pages/htmlexpv1-page.nix`
- `src/content/overview.md`
- `src/readme.nix`
- `src/htmlexpv1.nix`

Legacy files moved out of the product path:
- `src/legacy/example.nix`
- `src/legacy/googlesheets.nix`
- `src/legacy/hello.nix`
- `src/legacy/people.toml`

Product boundary

nixstix is now defined as:
a small Nix-first static HTML generator with a thin DSL, a pure renderer, and a site builder that writes static output into `$out`.

It is not:
- a CMS
- a blog engine
- a plugin platform
- a JS framework
- a dynamic server

Keep the boundary narrow.

Stable author-facing DSL surface

Treat this as the stable baseline for now:
- `text`
- `raw`
- `el`
- `attrs`
- `fragment`
- `page`
- `stylesheet`
- `script`
- `markdown`

Do not widen the DSL unless a real gap forces it.

What is intentionally deferred

- changes are staged but not yet committed
- no multi-system validation pass was added
- no broader feature expansion was attempted
- no theme/plugin/blog work was started

Guardrails for the next pass

Do:
- keep changes thin and local
- prefer pure functions and explicit contracts
- preserve the current architecture split
- validate with real Nix commands before finishing
- document only what actually exists

Do not:
- redesign the project into a larger framework
- add speculative abstractions
- reintroduce legacy experiments into the main package surface
- expand into dynamic features
- add broad features just because the refactor could support them

Recommended next pass

Pick only one small hardening/documentation target.

Best options:
1. add one more canonical authored page under `src/pages/`
2. add one tiny deterministic renderer check for escaping/attribute rendering
3. tighten the README with one precise authoring contract section for `page`, `el`, `text`, and `markdown`

Preferred order:
- first: tiny renderer check
- second: one more canonical page example
- third: author contract docs

Acceptance criteria for the next pass

Whichever small task is chosen, the pass should only count as complete if:
- `nix build .#default` succeeds
- `nix build .#readme` succeeds
- `nix build .#htmlexp` succeeds
- `nix flake check` succeeds
- the change remains within the current product boundary
- the summary clearly separates validated behavior from deferred work

Suggested commit message for the current staged work

- `refactor: split nixstix into DSL, renderer, and site builder; validate builds`

Suggested summary for the next session

Continue from the validated nixstix refactor.
Do not reopen architecture.
Keep the project as a small static-site generator.
Choose one thin hardening or documentation task, implement it with minimal diffs, and re-run full Nix validation before stopping.
