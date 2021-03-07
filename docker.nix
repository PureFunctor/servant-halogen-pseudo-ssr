{ doCheck ? false
, doMinimal ? true
}:
let
  config = import ./config.nix { inherit doCheck doMinimal; };
  inherit (config) pkgs hsPkgs;
in
  pkgs.dockerTools.streamLayeredImage {
    name = "site-backend";
    tag = "latest";
    contents = hsPkgs.servant-halogen-pseudo-ssr;
  }
