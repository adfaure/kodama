{
  inputs = {
    oxalica.url = "github:oxalica/rust-overlay";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, oxalica }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ oxalica.overlay ];
        config.allowUnfree = true;
      };

      # To update the tailwind packages use node2nix
      # node2nix -c tailwindcss.nix
      nodeDependencies = (pkgs.callPackage ({ pkgs, system }:
        let nodePackages = import ./tailwindcss.nix { inherit pkgs system; };
        in nodePackages // {
          shell = nodePackages.shell.override {
            buildInputs = [
              # pkgs.nodePackages.node-gyp-build
            ];
          };
        }) { }).shell.nodeDependencies;
    in {

      packages.x86_64-linux = {
        website = pkgs.stdenv.mkDerivation rec {
          version = "0.0.1";
          name = "batsite-${version}";
          src = pkgs.lib.sourceByRegex ./. [
            "^content"
            "^content/.*\.md"
            "^static"
            "^static/.*"
            "^templates"
            "^templates/.*"
            "^themes"
            "^themes/.*"
            "^styles"
            "^styles/.*\.css"
            "tailwind.config.js"
            "config.toml"
          ];
          buildInputs = [
            pkgs.zola
            pkgs.nodePackages.npm
          ];

          checkPhase = ''
            zola check
          '';

          buildPhase = ''
            ln -s ${nodeDependencies}/lib/node_modules ./node_modules
            export PATH="${nodeDependencies}/bin:$PATH"

            ls -l
            npx tailwindcss -i styles/styles.css -o static/styles/styles.css
          '';

          base-url = "https://batsim.org";
          installPhase = ''
            zola build -o $out --base-url ${base-url}
          '';
        };
      };
      # Use `nix develop` to activate the shell
      devShell.x86_64-linux = pkgs.mkShell {
        buildInputs = with pkgs; [
          zola
          nodeDependencies
          nodePackages.npm
          nodePackages.node2nix
        ];
        # This tells npx where to find the node lib.
        # The css generation can be done with:
        # npx tailwindcss -i styles/styles.css -o static/styles/styles.css
        NODE_PATH="${nodeDependencies}/lib/node_modules";
      };
    };
}
