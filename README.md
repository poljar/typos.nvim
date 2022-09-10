# typos.nvim

typos.nvim is a Neovim plugin that uses the [typos-cli] tool as a diagnostics
source. It provides diagnostic warnings for typos in your codebase with a low
false positive rate.

<!-- panvimdoc-ignore-start -->
## Screenshot

![Showcase](https://user-images.githubusercontent.com/552026/189417359-343b831e-62ad-43c2-b098-9062c8f9b478.png)

<!-- panvimdoc-ignore-end -->
## Prerequisites 

- `neovim 0.7`
- `null-ls` (optional, for code actions)

## Installation

using `packer.nvim`:

```lua
use 'poljar/typos.nvim'
```

## Stand-alone setup

typos.nvim can be set up without additional requirements to act as a diagnostics
source:

```lua
require('typos').setup()
```

## null-ls setup
typos.nvim can also be configured to act as a diagnostics and code actions source
for [null-ls].

To activate the code actions, just add our actions source to the list of active
sources in your null-ls setup function:

```lua
require('null-ls').setup({
    sources = {
        require('typos').actions,
    },
})
```

The same can be done for the diagnostic source:

```lua
require('null-ls').setup({
    sources = {
        require('typos').actions,
        require('typos').diagnostics,
    },
})
```

[typos-cli]: https://github.com/crate-ci/typos
[null-ls]: https://github.com/jose-elias-alvarez/null-ls.nvim
