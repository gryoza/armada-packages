# armada-packages

Upstream-derived packages for [armada](https://github.com/virtudude/armada), a
SteamOS-like Linux distribution for ARM handhelds. Each top-level directory is 
one component: a pinned upstream + `patches/` + a `build.sh`.

`build.sh` fetches the pinned upstream (`BASE.env`), applies `patches/`, and
builds. CI runs each into a `ghcr.io/virtudude/armada-packages/<component>`
image, path-triggered so bumping one doesn't rebuild the rest. armada pulls
those images at build time, pinned by digest.

`PATCHES.md` (per component) records where each patch came from.
