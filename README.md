# Nixstix

Static Site Generated Readme2Site with Nix

## Why?

Ever feel like the GitHub readme is a little too dull but you don't have the time to spruce up the documentation?

Static site generators have been around but they are not in the project repo oftentimes because the media assets can be a little clunky and bloaty and therefore docs are either in a separate repo or a submodule for bigger projects.

That separation of concern is when the project's documentation begins to tilt towards neglect and they get further away from new features and updates.

This template is meant to solve a problem in the beginning when you perform your inits. With Nix, it's a light-weight dependency graph based on nix-derivations in `nixlang`. If your project gets big, your documentation grows with it and hopefully flourishes as well.

## Why Nix?

Because an index.html is simply copied from nix builds, you can fearlessly rotate your documentationi without it spinning away from your core project. Static site generators need performance and community theming to raid boss fight against wordpress and evil proprietary software. But a humble landing page of a repo simply needs to look and feel modern, inviting and have your branding with minimal effort to an efficient end.

The only dependency is `cmark-gfm` and `taskfile`. The latter is mainly for the helpers and built-in completions.

```bash
task deploy:readme
```

## ToDos

-[ ] While this isn't a blog or a website. It certainly has the ability to morph into anything and everything with nix and version control. Therefore, I'm looking to integrate further into lazygit or some kind of charm TUI framework to make choosing themes from [cssbed](https://cssbed.com)
-[ ] WASM. One thing I have discovered is that Github static site hosting does work with serving wasm mime-types correctly and therefore, there are some really neat sensible defaults to be had with minimal scripting.
-[ ] First things first, github pages deploy

## Picture puurrrrfect

Documentation doesn't need pictures, and often times they can be distracting. That's why READMEs stay bland while the landing page gets to do branding or marketing on some more real estate. `tgpt` just so happens to be a great little terminal tool to generate images and my task piping awks back a link to the image in `markdown` format.

```bash
task mdimg -- <prompt for an image>
```

## Stay tuned

---
