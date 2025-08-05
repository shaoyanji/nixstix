{
  pkgs ? import <nixpkgs> {},
  lib,
  runCommandWith,
  cmark-gfm,
  htmlq,
}: let
  fw =
    head [
      (meta "charset" "utf-8")
      (meta "name" "viewport")
      (meta "content" "width=device-width, initial-scale=1")
      (title "h1")
      (styles.links [
        cssbed.yorha
        # cssbed.sakura-vader
        bx.brands
        # franken.link
      ])
    ]
    |> dochtml (lang "en")
    <| body [
      # pines.navbar
      # franken.navbar
      contents
      (alpinejs.toggle "src" <| codify sourcefile.content)
      (alpinejs.toggle "Tech used" banner)
      (scripts [
        alpinejs.link
        # datastar
        # tailwind
      ])
      # htmz
    ];
  datastar = "https://cdn.jsdelivr.net/gh/starfederation/datastar@main/bundles/datastar.js";
  htmz = ''<iframe hidden name=htmz onload='setTimeout(()=>document.querySelector(contentWindow.location.hash||null)?.replaceWith(...contentDocument.body.childNodes))'></iframe>'';
  franken.link = "https://cdn.jsdelivr.net/npm/franken-ui@2.1.0-next.16/dist/css/core.min.css";
  franken.navbar =
    /*
    html
    */
    ''
      <nav aria-label="Breadcrumb">
        <ul class="uk-breadcrumb">
          <li><a href="#">Home</a></li>
          <li><a href="#">Linked Category</a></li>
          <li class="uk-disabled"><a>Disabled Category</a></li>
          <li>
            <span aria-current="page">Franken UI</span>
          </li>
        </ul>
      </nav>
    '';
  pines.navbar =
    /*
    html
    */
    ''


      <nav class='flex justify-between'>
          <ol class='inline-flex items-center mb-3 space-x-3 text-sm text-neutral-500 [&_.active-breadcrumb]:text-neutral-500/80 sm:mb-0'>
              <li class='flex items-center h-full'><a href='#_' class='py-1 hover:text-neutral-900'><svg class='w-4 h-4' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='currentColor'><path d='M11.47 3.84a.75.75 0 011.06 0l8.69 8.69a.75.75 0 101.06-1.06l-8.689-8.69a2.25 2.25 0 00-3.182 0l-8.69 8.69a.75.75 0 001.061 1.06l8.69-8.69z' /><path d='M12 5.432l8.159 8.159c.03.03.06.058.091.086v6.198c0 1.035-.84 1.875-1.875 1.875H15a.75.75 0 01-.75-.75v-4.5a.75.75 0 00-.75-.75h-3a.75.75 0 00-.75.75V21a.75.75 0 01-.75.75H5.625a1.875 1.875 0 01-1.875-1.875v-6.198a2.29 2.29 0 00.091-.086L12 5.43z' /></svg></a></li>
              <span class='mx-2 text-gray-400'>/</span>
              <li><a href='#_' class='inline-flex items-center py-1 font-normal hover:text-neutral-900 focus:outline-none'>Projects</a></li>
              <span class='mx-2 text-gray-400'>/</span>
              <li><a class='inline-flex items-center py-1 font-normal rounded cursor-default active-breadcrumb focus:outline-none'>Pines</a></li>
          </ol>
      </nav>


    '';
  tailwind = "https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4";
  dochtml = l: head: body: ''<!doctype html>${l}${head}${body}</html>'';
  lang = l: ''<html lang="${l}">'';
  head = h: ''<head>${lib.concatStrings h}</head>'';
  meta = n: f: ''<meta ${n}="${f}" >'';
  body = b: ''<body>${lib.concatStrings b}</body>'';
  contents = "$(${md2html sourcefile.path})";
  title = t: ''<title>$(${htmlquery sourcefile.path "${t}"})</title>'';
  scripts = ss: builtins.concatMap (x: ["<script src=" x " defer></script>"]) ss |> lib.concatStrings;
  styles = {
    links = sty: builtins.concatMap (x: ["<link rel='stylesheet' href= " x " >"]) sty |> lib.concatStrings;
  };
  alpinejs = {
    link = "https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js";
    toggle = n: r:
    /*
    html
    */
    ''
      <div x-data='{ open: false }'>
        <button @click='open = ! open'>${n}</button>
        <div x-show='open' @click.outside='open = false' x-transition> ${builtins.toString r}</div>
      </div>
    '';
  };

  bx = {
    icons = i: builtins.concatMap (x: ["<i class='" x "' ></i>"]) i |> lib.concatStrings;
    brands = "https://cdn.boxicons.com/fonts/brands/boxicons-brands.min.css";
  };
  cssbed = {
    awsm = "https://unpkg.com/awsm.css/dist/awsm.min.css";
    bahunya = "https://cdn.jsdelivr.net/gh/kimeiga/bahunya@css/bahunya-0.1.3.css";
    bamboo = "https://unpkg.com/bamboo.css";
    holiday = "https://cdn.jsdelivr.net/npm/holiday.css";
    kacit = "https://cdn.jsdelivr.net/gh/Kimeiga/kacit/kacit.min.css";
    minicss = "https://cdn.jsdelivr.net/gh/Chalarangelo/mini.css@v3.0.1/dist/mini-default.min.css";
    no-class = "https://davidpaulsson.github.io/no-class/css/no-class.min.css";
    picocss = "https://unpkg.com/@picocss/pico@latest/css/pico.classless.min.css";
    sakura = "https://unpkg.com/sakura.css/css/sakura.css";
    sakura-vader = "https://unpkg.com/sakura.css/css/sakura-vader.css";
    simplecss = "https://cdn.simplecss.org/simple.css";
    stylize = "https://vasanthv.github.io/stylize.css/stylize.css";
    tacit = "https://cdn.jsdelivr.net/gh/yegor256/tacit@gh-pages/tacit-css-1.5.0.min.css";
    tufte = "https://edwardtufte.github.io/tufte-css/tufte.css";
    vanilla = "https://vanillacss.com/vanilla.css";
    w3c-choco = "https://www.w3.org/StyleSheets/Core/Chocolate";
    w3c-trad = "https://www.w3.org/StyleSheets/Core/Traditional";
    water-dark = "https://cdn.jsdelivr.net/gh/kognise/water.css@latest/dist/dark.css";
    water-light = "https://cdn.jsdelivr.net/gh/kognise/water.css@latest/dist/light.css";
    writ = "https://writ.cmcenroe.me/1.0.4/writ.min.css";
    yorha = "https://cdn.jsdelivr.net/npm/yorha@1.2.0/dist/yorha.min.css";
  };
  index = "$out/index.html";
  md2html = md: "cat ${md} | cmark-gfm -t html";
  htmlquery = md: q: "${md2html md} | htmlq -t ${q}";
  codify = c: ''
    <code>${c}</code>
  '';
  banner = lib.concatStrings [
    ''made in germany with love ❤️''
    (bx.icons [
      "bxl bx-html5"
      "bxl bx-bash"
      "bxl bx-github"
    ])
  ];
  sourcefile = {
    content = builtins.readFile ./README.md;
    path = ./README.md;
  };
in
  runCommandWith {
    name = "nixstix";
    derivationArgs.nativeBuildInputs = [cmark-gfm htmlq];
  }
  /*
  bash
  */
  ''
    mkdir -p $out
    echo "${fw}" > ${index}
  ''
