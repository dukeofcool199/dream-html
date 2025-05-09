{
  inputs = { nixpkgs.url = "github:nix-ocaml/nix-overlays"; };

  outputs = { nixpkgs, self, ... }:
    let
      eachSystem = f:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system:
          f (nixpkgs.legacyPackages.${system}.extend (_self: super: {
            # You can set the OCaml version to a particular release. Also, you
            # may have to pin some packages to a particular revision if the
            # devshell fail to build. This should be resolved in the upstream.
            ocamlPackages = super.ocaml-ng.ocamlPackages_latest;
          })));
    in {
      packages = eachSystem (pkgs:
        with pkgs; rec {
          pure-html = ocamlPackages.buildDunePackage {
            pname = "pure-html";
            version = "pure-html";
            duneVersion = "3";
            src = self.outPath;

            # Uncomment if you need the executable of dream_eml during build
            # nativeBuildInputs = [
            #   ocamlPackages.dream
            # ];

            buildInputs = with ocamlPackages; [ ocaml-syntax-shims ];

            propagatedBuildInputs = with ocamlPackages; [
              # Add OCaml dependencies required for your project

              # Jane Street
              base
              core
              core_unix
              dream
              uri

              # Some common dependencies
              # eio
              # eio_main
              # yojson
              # ppx_yojson_conv
            ];
          };
          dream-html = ocamlPackages.buildDunePackage {
            pname = "dream-html";
            version = "dream-html";
            duneVersion = "3";
            src = self.outPath;

            # Uncomment if you need the executable of dream_eml during build
            # nativeBuildInputs = [
            #   ocamlPackages.dream
            # ];

            buildInputs = with ocamlPackages; [ ocaml-syntax-shims ];

            propagatedBuildInputs = with ocamlPackages; [
              # Add OCaml dependencies required for your project

              # Jane Street
              dream
              uri
              pure-html

              # Some common dependencies
              # eio
              # eio_main
              # yojson
              # ppx_yojson_conv
            ];
          };
          default = dream-html;
        });

      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ self.packages.${pkgs.system}.default ];
          packages = (with pkgs.ocamlPackages; [
            ocaml-lsp
            ocamlformat
            ocp-indent
            utop
            # Needed for generating documentation
            opam
            odoc
            odig
            # This may fail to build, so it is turned off by default.
            # (sherlodoc.override { enableServe = true; })
          ])
          # Enable file watcher.
          # ++ lib.optional pkgs.stdenv.isLinux pkgs.inotify-tools
          ;
        };
      });
    };
}
