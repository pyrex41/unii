# Build manifest

The machine-readable copy is `manifest.lua`. The build and the tests
read that file, so update it first and then keep this page in step.

## Pinned revisions

| Item | Value |
|---|---|
| shen-lua | `fc9757731580f77aad6b3b4cea53773261b36d44` (merge of pyrex41/shen-lua#71, release 0.11.1, 2026-09-28), from <https://github.com/pyrex41/shen-lua>. Pinned as the git submodule `vendor/shen-lua` and as the flake input `shen-lua`. |
| shen-lua flake input | `github:pyrex41/shen-lua/fc9757731580f77aad6b3b4cea53773261b36d44`, `flake = false`, narHash `sha256-5V96MYsxxOXg4RDJ/OuTgWbVjtdpIy+RyAc6iVRt6VQ=` (`flake.lock`) |
| Shen kernel | Shen 42 (S42 2026-08-25 refresh; see `vendor/shen-lua/klambda/PROVENANCE.md`) |
| UniiChat gist | revision `3c190e06f34aba0c69f49042c526093269604935` (2026-10-08T01:58:24Z), file `optchat.md`, 19,092 bytes |
| gist sha256 | `12f300f760af82bc07bc5201051d1267824ded09c9def8186e4f8144368038d8` (git blob `4c09901baa3685852bf252cdb70ace81d01d6be5`) |
| nixpkgs | `a5cc6f2c37bf518436dc8d1c288ccd0c43c2f4c4`, the same pin and narHash as shen-lua's own `flake.lock` at the pinned commit |

`build.lua` (through `host/shen_lua.lua`) refuses to build if the runtime
is a git checkout at another commit, or with tracked changes or untracked,
non-ignored files, or if `UNII_SHEN_LUA_REV` (set by the dev shell) names
another commit. `test_boundary.lua` checks the same, checks that
`manifest.lua`, the submodule gitlink, `flake.nix` and `flake.lock` name one
commit, and
re-downloads the gist at the pinned revision and checks its size, sha256
and git blob id. Set `UNII_OFFLINE=1` to skip that download.

## Toolchain

| Item | Value |
|---|---|
| Runtime | LuaJIT 2.1. No other dependencies: SHA-256, the codec and the POSIX bindings are in-tree and use the LuaJIT FFI. |
| Verified with Nix | LuaJIT 2.1.1774638290 from `nix develop` (`/nix/store/damwm6hccy1ryvjsjizfjrxf8rmcraia-luajit-2.1.1774638290`), shen-lua from the flake input |
| Verified on Ubuntu | LuaJIT 2.1.1703358377, Ubuntu 24.04 package `2.1.0+git20231223.c525bcb+dfsg-1ubuntu0.1`, shen-lua from the submodule |
| Platform | Linux x86_64 verified. `host/posix.lua` has flag tables for Linux aarch64 and macOS, but neither has been run. |
| Dev shell | `nix develop`: luajit, git, curl, gnumake, coreutils, python3, openssl; `UNII_SHEN_LUA` and `UNII_SHEN_LUA_REV` point at the shen-lua flake input |
| Tests also use | `git` (the pinning checks and the gist blob id), `curl` (the gist download), libcurl (the real adapter), `python3` and `openssl` (the adapter's local test server and certificates), and `make` (`--with-upstream`) |

## Rule bundle

| Item | Value |
|---|---|
| Files, in load order | `core/arith.shen types.shen tree.shen view.shen jobs.shen transition.shen invariants.shen` |
| Bundle hash | sha256 over the files' bytes and `bundle_format`. At the time of writing: `6873743ffa59156a795213c50e4ca96c97e73be86de87536862114385ee4310a` |
| Formats | `bundle_format` 1, `storage_format` 2, `codec_version` 1 |

`unii build`, which also runs at the start of `luajit test/run.lua`,
does the following:

1. Loads the bundle under `(tc +)` with the fasl cache off
   (`SHEN_FASL=off`), so the kernel typechecker really runs.
2. Checks that an ill-typed fixture is rejected.
3. Writes `build/bundle.stamp`: the bundle hash, the format, the files, the
   shen-lua pin, whether the pin was verified (`shen_lua_verified`), and the
   LuaJIT version.

At boot, the host refuses any bundle whose hash does not match the stamp. A
journal written under a different bundle is refused when it is opened.

## License

BSD-3-Clause, the same terms as the shen-lua port it was developed in
(Reuben Brooks); see `LICENSE`. The shen-lua submodule keeps its own
`LICENSE`: the port is BSD-3-Clause (Reuben Brooks), and the Shen kernel and
its tests are BSD-3-Clause (Mark Tarver). The gist is used as a design source and test oracle, and
none of its text is vendored.
