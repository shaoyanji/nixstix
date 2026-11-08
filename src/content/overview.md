---
title: Overview
description: What nixstix keeps out of scope, and what that buys.
navOrder: 20
---

## Thin by design

- `nixstix` keeps the model explicit: page AST, renderer, builder.
- The default build preserves the README publishing flow and adds a nested DSL-authored page.
- Static assets are copied directly into the site output, so the result stays GitHub Pages-friendly.

A markdown file in `src/content/` is a page with no page module: the route comes
from its path, so `src/content/overview.md` is `/overview/` and nothing else has
to be declared.
