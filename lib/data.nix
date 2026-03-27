{ }:
{
  fromJSONFile = path:
    builtins.fromJSON (builtins.readFile path);

  fromTOMLFile = path:
    builtins.fromTOML (builtins.readFile path);
}
