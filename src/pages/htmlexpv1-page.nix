{ dsl, stylesheetHref ? "/assets/site.css" }:
let
  inherit (dsl) el page raw script stylesheet text;
in
page {
  title = "HTML Experiment";
  route = "experiments/htmlexpv1/index.html";
  description = "A migrated nixstix HTML DSL experiment built on the shared renderer.";
  head = [
    (stylesheet stylesheetHref)
  ];
  body = [
    (el "div" { class = "page-shell"; } [
      (el "header" { class = "site-header"; } [
        (el "div" {} [
          (el "div" { class = "site-title"; } [ (text "HTML Experiment") ])
          (el "p" { class = "lede"; } [ (text "The old prototype helpers now author against the shared DSL and renderer.") ])
        ])
        (el "nav" { "aria-label" = "Primary"; } [
          (el "a" { href = "/"; } [ (text "Back to home") ])
        ])
      ])
      (el "main" { class = "demo-stack"; } [
        (el "section" { class = "card"; } [
          (el "h1" {} [ (text "Shared primitives") ])
          (el "p" {} [
            (text "This page is authored with ")
            (el "code" {} [ (text "dsl.el") ])
            (text ", ")
            (el "code" {} [ (text "dsl.fragment") ])
            (text ", and ")
            (el "code" {} [ (text "dsl.page") ])
            (text " rather than embedding HTML in one derivation.")
          ])
          (el "div" { class = "chip-row"; } [
            (el "span" { class = "chip"; } [ (text "small AST") ])
            (el "span" { class = "chip"; } [ (text "pure render step") ])
            (el "span" { class = "chip"; } [ (text "multipage routes") ])
          ])
        ])
        (el "section" { class = "card"; } [
          (el "h2" {} [ (text "Raw HTML still exists when needed") ])
          (raw "<details><summary>raw node</summary><p>Use <code>dsl.raw</code> for trusted snippets you do not want escaped.</p></details>")
        ])
      ])
    ])
    (script "https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js")
  ];
}
