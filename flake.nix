{
  description = "unii development environment (pinned; see manifest.lua)";

  # Same nixpkgs revision as shen-lua's flake.lock at the pinned commit.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/a5cc6f2c37bf518436dc8d1c288ccd0c43c2f4c4";

  # The shen-lua runtime, pinned to manifest.shen_lua.commit (also the
  # vendor/shen-lua submodule). Source only: unii loads it from the store.
  inputs.shen-lua = {
    url = "github:pyrex41/shen-lua/fc9757731580f77aad6b3b4cea53773261b36d44";
    flake = false;
  };

  outputs = { self, nixpkgs, shen-lua }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.luajit pkgs.git pkgs.curl pkgs.gnumake pkgs.coreutils pkgs.python3 pkgs.openssl
          ];
          UNII_SHEN_LUA = "${shen-lua}";
          UNII_SHEN_LUA_REV = shen-lua.rev;
          # host/network/curl_ffi.lua dlopens libcurl.so.4, which Nix's
          # LuaJIT cannot find without this.
          LD_LIBRARY_PATH = pkgs.lib.optionalString pkgs.stdenv.isLinux
            (pkgs.lib.makeLibraryPath [ pkgs.curl ]);
          shellHook = ''
            echo "unii dev shell: $(luajit -v)"
            echo "shen-lua runtime: $UNII_SHEN_LUA ($UNII_SHEN_LUA_REV)"
            echo "run all checks: luajit test/run.lua   (from the repository root)"
          '';
        };
      });
    };
}
