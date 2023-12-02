{
  description = "Collection of frequently used flake modules";

  outputs = { self, ... }:
    {
      mkJsModule = import ./modules/javascript.nix;
      js = self.mkJsModule { devShellName = "default"; };

      mkReplaceInFileModule = import ./modules/replace-in-file.nix;
      replace-in-file = self.mkReplaceInFileModule { devShellName = "default"; };
    };
}
