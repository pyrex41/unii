# unii

unii (a provisional name) is the memory engine for an endless conversation
agent: a typechecked, pure Shen rule bundle decides tree addressing, exact
leaves, lossless joins, summary jobs, view coverage, merge order and batch
hysteresis, and a LuaJIT host does the codec, journal, storage, supervisor,
network adapter, provider and CLI.

It runs on [shen-lua](https://github.com/pyrex41/shen-lua) (Shen 42 on
LuaJIT), pinned at `fc9757731580f77aad6b3b4cea53773261b36d44` (release
0.11.1) as the git submodule `vendor/shen-lua` and as a Nix flake input.
unii was developed in shen-lua's `unii/` directory (pyrex41/shen-lua#74,
pyrex41/shen-lua#75, pyrex41/shen-lua#76, pyrex41/shen-lua#77); its history
was carried over with
`git filter-repo --subdirectory-filter unii`.

## Quick start

Requires LuaJIT 2.1, git, curl and libcurl; the adapter tests also use
python3 and openssl, and `--with-upstream` uses make. `nix develop` provides
all of them.

```sh
git clone --recurse-submodules https://github.com/pyrex41/unii
cd unii                               # run everything from the repository root
# (existing clone: git submodule update --init)

luajit test/run.lua                   # typechecked build + main suite
luajit test/run.lua --with-upstream   # also shen-lua's port specs and Shen 42 kernel suite
luajit test/network/run.lua           # libcurl adapter suite (live smoke skips without a key)
luajit eval/oracle/spec.lua           # independent oracle
luajit eval/oracle/generate_fixtures.lua --check

bin/unii milestone --dir /tmp/chat    # multi-process restart demonstration
```

Set `UNII_OFFLINE=1` to skip the test that downloads the pinned gist.

## Documentation

* `docs/HANDOFF.md`: status, layout, runtime pin, acceptance gates, known
  limits and next steps.
* `docs/MANIFEST.md` (and `manifest.lua`): pinned revisions, toolchain,
  bundle and format versions, license.
* `docs/contracts/`: events, commands, numeric policy, codec, storage,
  network, oracle, decisions.
* `docs/STORAGE_PHASE2.md`: durable storage and fault matrix.

## Known upstream issue

shen-lua at the pinned commit cannot load datatype rules with six or more
premises over user datatypes, so `core/types.shen` nests records to keep
every rule at five premises or fewer. pyrex41/shen-lua#78 fixes this; the
nesting workaround can be dropped once the pin moves past that fix (see
`docs/HANDOFF.md`, "Upstream issue").

## License

BSD-3-Clause; see `LICENSE`. The shen-lua submodule carries its own license.
