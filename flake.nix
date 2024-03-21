{
  description = "PostgreSQL zero-downtime migrations made easy";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    # flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    flake-compat.url = "github:9999years/flake-compat/fix-64";
  };

  outputs = { self, nixpkgs, flake-compat }:
    let
      pname = "pgroll";
      version = "0.5.0";

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in
    {

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};

        in
        {
          pgroll = pkgs.buildGoModule {
            inherit pname;
            inherit version;

            src = pkgs.fetchFromGitHub {
              owner = "xataio";
              repo = pname;
              rev = "889946b26dbf58aa8458d33e3600ac9f91862376";
              hash = "sha256-VYGwIJsPVilFxvglj+E7H9NpqUV1CV/ggBP3gFleWIA=";
              # hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            };

            # This hash locks the dependencies of this package. It is
            # necessary because of how Go requires network access to resolve
            # VCS.  See https://www.tweag.io/blog/2021-03-04-gomod2nix/ for
            # details. Normally one can build with a fake sha256 and rely on native Go
            # mechanisms to tell you what the hash should be or determine what
            # it should be "out-of-band" with other tooling (eg. gomod2nix).
            # To begin with it is recommended to set this, but one must
            # remeber to bump this hash when your dependencies change.
            # vendorSha256 = pkgs.lib.fakeSha256;

            # vendorHash = null;
            # vendorHash = pkgs.lib.fakeHash;
            vendorHash = "sha256-Fz+o1jSoMfqKYo1I7VUFqbhBEgcoQEx7aYsmzCLsbnI=";

            doCheck = false; # disabling checkPhase as it requires docker for testcontainers-go

          };
        });

      # Add dependencies that are only needed for development
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ go gopls gotools go-tools ];
          };
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.pgroll);
    };
}
