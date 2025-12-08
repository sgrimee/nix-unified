_final: prev: let
  pname = "gitui";
  version = "0.27.0";
  tarballUrl = "https://github.com/gitui-org/gitui/releases/download/v${version}/gitui-mac.tar.gz";
  sha256 = "0236dnc2ybj32qi7bq6683mgblq21vvjb78byvlavmidfhk94zqn";
in {
  # Fix gitui build failure on aarch64-darwin
  # Issue: sha1-asm crate fails to compile with newer clang versions
  # The assembly syntax is incompatible with macOS assembler
  # Workaround: Use pre-built binary from GitHub releases
  # Upstream issues:
  # - https://github.com/NixOS/nixpkgs/issues/450861
  # - https://github.com/NixOS/nixpkgs/issues/456688
  # - https://github.com/RustCrypto/asm-hashes/issues/28
  gitui =
    if prev.stdenv.isDarwin && prev.stdenv.hostPlatform.system == "aarch64-darwin"
    then
      prev.stdenvNoCC.mkDerivation {
        inherit pname version;
        src = prev.fetchurl {
          url = tarballUrl;
          inherit sha256;
        };

        nativeBuildInputs = [prev.gnutar prev.gzip];
        unpackPhase = "true";
        installPhase = ''
          mkdir -p $out/bin
          ${prev.gnutar}/bin/tar -xzf $src
          install -m755 gitui $out/bin/gitui
        '';

        meta = with prev.lib; {
          description = "Blazing fast terminal-ui for git written in Rust (binary package for Apple Silicon)";
          homepage = "https://github.com/gitui-org/gitui";
          license = licenses.mit;
          platforms = ["aarch64-darwin"];
          maintainers = [];
        };
      }
    else prev.gitui;
}
