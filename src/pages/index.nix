{
  dsl,
  markdown,
  readmePath,
  overviewPath ? null,
  stylesheetHref ? "/assets/site.css",
}:
let
  inherit (dsl) el page stylesheet text;
in
page {
  title = "Nixstix";
  route = "index.html";
  description = "A thin Nix-first static site generator for HTML and README publishing.";
  head = [
    (stylesheet stylesheetHref)
  ];
  body = [
    (el "div" { class = "page-shell"; } [
      (el "header" { class = "site-header"; } [
        (el "div" {} [
          (el "div" { class = "site-title"; } [ (text "nixstix") ])
          (el "p" { class = "lede"; } [
            (text "A Nix-first static HTML generator with a small DSL, a pure renderer, and a builder that emits a deployable site directory.")
          ])
        ])
        (el "nav" { "aria-label" = "Primary"; } [
          (el "a" { href = "/"; } [ (text "Home") ])
          (el "a" { href = "/experiments/htmlexpv1/"; } [ (text "HTML Experiment") ])
        ])
      ])
      (el "main" {} [
        (el "section" { class = "hero"; } [
          (el "h1" {} [ (text "README to site, without leaving Nix.") ])
          (el "p" {} [
            (text "The default build keeps the README publishing flow intact while making room for authored pages and nested routes.")
          ])
        ])
        (el "section" { class = "card-grid"; } [
          (el "article" { class = "card"; } [
            (el "h2" {} [ (text "DSL") ])
            (el "p" {} [ (text "Pure Nix node constructors for pages, fragments, elements, assets, and markdown hooks.") ])
          ])
          (el "article" { class = "card"; } [
            (el "h2" {} [ (text "Renderer") ])
            (el "p" {} [ (text "AST to HTML string conversion is isolated from the site build logic.") ])
          ])
          (el "article" { class = "card"; } [
            (el "h2" {} [ (text "Builder") ])
            (el "p" {} [ (text "Routes, pages, and static assets are emitted into a GitHub Pages-friendly directory tree.") ])
          ])
        ])
        (if overviewPath == null then null else
          (el "section" { class = "card"; } [
            (dsl.markdown (markdown.fromFile overviewPath))
          ]))
        (el "section" { class = "readme"; } [
          (dsl.markdown (markdown.fromFile readmePath))
        ])
      ])
    ])
  ];
}
