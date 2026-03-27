{ lib }:
let
  escapeHtml = value:
    lib.replaceStrings
      [ "&" "<" ">" "\"" "'" ]
      [ "&amp;" "&lt;" "&gt;" "&quot;" "&#39;" ]
      (builtins.toString value);

  renderAttrs = attrs:
    lib.concatStrings (
      lib.mapAttrsToList
        (name: value:
          if value == null || value == false then ""
          else if value == true then " ${name}"
          else " ${name}=\"${escapeHtml value}\"")
        attrs
    );

in
rec {
  inherit escapeHtml;

  renderElement = node:
    let
      attrsString = renderAttrs node.attrs;
      children = lib.concatMapStrings renderNode node.children;
    in
    "<${node.name}${attrsString}>${children}</${node.name}>";

  renderHead = page:
    let
      descriptionMeta =
        if page.description == null then []
        else [ "<meta name=\"description\" content=\"${escapeHtml page.description}\">" ];
    in
    ''
      <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>${escapeHtml page.title}</title>
      ${lib.concatStrings descriptionMeta}
      ${lib.concatMapStrings renderNode page.meta}
      ${lib.concatMapStrings renderNode page.head}
      </head>
    '';

  renderNode = node:
    if node.type == "text" then escapeHtml node.value
    else if node.type == "raw" then node.value
    else if node.type == "fragment" then lib.concatMapStrings renderNode node.children
    else if node.type == "element" then renderElement node
    else if node.type == "stylesheet" then
      "<link rel=\"stylesheet\" href=\"${escapeHtml node.href}\"${renderAttrs node.attrs}>"
    else if node.type == "script" then
      "<script src=\"${escapeHtml node.src}\"${renderAttrs node.attrs}></script>"
    else if node.type == "markdown" then node.spec.html
    else throw "nixstix.render encountered an unsupported node type";

  renderPage = page:
    ''
      <!doctype html>
      <html lang="${escapeHtml page.lang}"${renderAttrs page.attrs}>
      ${renderHead page}
      <body>${lib.concatMapStrings renderNode page.body}</body>
      </html>
    '';
}
