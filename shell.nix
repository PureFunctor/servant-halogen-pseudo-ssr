{ doCheck ? false 
, doMinimal ? false
}:

let
  config = import ./config.nix { inherit doCheck doMinimal; };
  inherit (config) compiler pkgs hsPkgs;

  sources = import ./nix/sources.nix { };

  gitignore = import sources."gitignore.nix" { };
  inherit (gitignore) gitignoreSource;

  name = "development-shell";

  buildInputs = [
    pkgs.cabal-install
  ];

in
  hsPkgs.shellFor {
    inherit name buildInputs;
    packages = _: [
      hsPkgs.servant-halogen-pseudo-ssr
    ];
  }
