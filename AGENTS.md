# async-iterators.nvim

A minimal Neovim plugin to

> **This project is small. When working on it, read the source at `lua/async_iterators/init.lua` directly and include it in context — that's more reliable than any summary here.**

## Project overview

- **Source**: `lua/async_iterators/init.lua` — all logic in one module
- **Docs**: `README.md`
- **Makefile**: `makefile`
- **Tests**: `tests/test_e2e.lua` — see the `testing` skill
- **Scripts**: `scripts/minimal_init.lua` — Neovim init for headless testing
- **No dependencies** beyond Neovim builtins (`vim.text.diff`, `vim.system`, `vim.uv`)
- **Targets nightly Neovim**. Uses modern APIs — when in doubt, check `:help` docs.
  - To look up a Neovim API: `nvim --headless -c "help vim.text.diff" -c ".,.+100w! /tmp/help.txt" -c "qa" 2>&1`
  - Adjust `100` as needed

## Style preferences

- Use Lua long strings (`[[...]]`) for multi-line string literals instead of escaped `\n`.
- Do not declare multiple variables on one line — use one `local` per line.
- In tests, avoid raw `child.lua` strings — they are prone to bugs. If you must use a `child.lua` string, make a helper function that takes arguments rather than embedding logic inline.
