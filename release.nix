{ doCheck ? false
, doMinimal ? true
}:

let
  config = import ./config.nix { inherit doCheck doMinimal; };
  inherit (config) hsPkgs;

in
  { servant-halogen-pseudo-ssr = hsPkgs.servant-halogen-pseudo-ssr;
  }
