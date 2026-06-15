# Patches

Patches applied on top of BASE.env. Each entry's `source` is an upstream URL pinned
to a commit, or `armada` if it's original; a URL source with no `notes` is verbatim.
`notes` mean the file was modified.

- `patches/0001-fix-freedreno-vulkan.patch`
  source: https://github.com/batocera-linux/batocera.linux/blob/bca5c05d90b606ad859ba2e4e82ab0a515ccb956/board/batocera/patches/mesa3d/001-fix-freedreno-vulkan.patch
- `patches/0002-add-a830-chip-id.patch`
  source: https://github.com/ROCKNIX/distribution/blob/e485495a942daba186d4a8543e18a1ad09c9a5d5/projects/ROCKNIX/packages/graphics/mesa/patches/SM8750/0001-add-a830-chip-id.patch
  notes: modified — ported from ROCKNIX, chip-id additions verbatim
