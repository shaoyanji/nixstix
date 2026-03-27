{ lib }:
let
  isPrimitive = value:
    lib.isString value
    || lib.isInt value
    || lib.isFloat value
    || lib.isBool value;

  normalizeAttrs = value:
    if value == null then {}
    else if lib.isAttrs value then value
    else throw "nixstix.dsl.attrs expects an attribute set or null";

in
rec {
  normalizeNode = value:
    if value == null then fragment []
    else if lib.isList value then fragment value
    else if lib.isAttrs value && value ? type then value
    else if isPrimitive value then text value
    else throw "nixstix.dsl received an unsupported node value";

  normalizeChildren = children:
    builtins.map normalizeNode (lib.flatten [ children ]);

  attrs = normalizeAttrs;

  text = value: {
    type = "text";
    value = builtins.toString value;
  };

  raw = value: {
    type = "raw";
    value = builtins.toString value;
  };

  fragment = children: {
    type = "fragment";
    children = normalizeChildren children;
  };

  el = name: attributes: children: {
    type = "element";
    inherit name;
    attrs = normalizeAttrs attributes;
    children = normalizeChildren children;
  };

  stylesheet = value:
    let
      spec =
        if lib.isAttrs value then value
        else {
          href = value;
          attrs = {};
        };
    in
    {
      type = "stylesheet";
      href = spec.href;
      attrs = normalizeAttrs (spec.attrs or {});
    };

  script = value:
    let
      spec =
        if lib.isAttrs value then value
        else {
          src = value;
          attrs = { defer = true; };
        };
    in
    {
      type = "script";
      src = spec.src;
      attrs = normalizeAttrs (spec.attrs or {});
    };

  markdown = spec: {
    type = "markdown";
    inherit spec;
  };

  page = {
    title,
    body,
    route ? "index.html",
    lang ? "en",
    head ? [],
    meta ? [],
    attrs ? {},
    description ? null,
  }: {
    type = "page";
    inherit title route lang description;
    head = normalizeChildren head;
    meta = normalizeChildren meta;
    body = normalizeChildren body;
    attrs = normalizeAttrs attrs;
  };
}
