<div align="center">

# color-converter.nvim

![License](https://img.shields.io/github/license/NTBBloodbath/doom-one.nvim?style=flat-square)
![Neovim version](https://img.shields.io/badge/Neovim-0.5-57A143?style=flat-square&logo=neovim)

[Features](#features) • [Install](#install) • [Usage](#usage) • [Contribute](#contribute)

<img width="800" src="./assets/demo.svg" />
  
</div>

Easily convert your CSS colors without leaving your favorite editor.

## Features

- Cycle between HEX, RGB and HSL or directly convert to one of them, e.g. from RGB to HEX.
- No external dependencies!

## Install

Packer
```lua
use 'NTBBloodbath/color-converter.nvim'
require('color-converter').setup({})
```

Lazy
```lua
return {
  "NTBBloodbath/color-converter.nvim",
  opts = {},
}
```

## Usage

Just configure the [commands](#commands), place the cursor over the line
containing the CSS color and trigger the command that you want.

### Commands

`color-converter.nvim` respects your keyboard shortcuts, so it doesn't create
any by default. Instead, expose commands so you can create keyboard shortcuts
yourself. These commands are the following:

- `<Plug>ColorConvertCycle`
  - Cycle between `HEX`, `RGB` and `HSL`.
- `<Plug>ColorConvertHEX`
  - Convert the current color to `HEX`.
- `<Plug>ColorConvertRGB`
  - Convert the current color to `RGB`.
- `<Plug>ColorConvertHSL`
  - Convert the current color to `HSL`.

### Configuration
  This is the default configuration:

```lua
{
  hsl_pattern = "hsl(%d, %g%%, %g%%)",
  hsla_pattern = "hsla(%d, %d%%, %d%%, %g)",
  rgb_pattern = "rgb(%d, %d, %d)",
  rgba_pattern = "rgba(%d, %d, %d, %g)",
}
```

You can update the patterns to use modern syntax without the comma separator, ie.
`hsl_pattern = "hsl(%d %g%% %g%%)"`

## Acknowledgements

- VSCode for the idea and some of the converters

## Contribute

1. Fork it (https://github.com/NTBBloodbath/color-converter.nvim/fork)
2. Create your feature branch (<kbd>git checkout -b my-new-feature</kbd>)
3. Commit your changes (<kbd>git commit -am 'Add some feature'</kbd>)
4. Push to the branch (<kbd>git push origin my-new-feature</kbd>)
5. Create a new Pull Request

## Todo

- [x] Support RGBA and HSLA
- [ ] Proper support for HEX with Alpha field (`#RRGGBBAA`)
- [ ] Add a command to select the conversion in a floating window

## License

`color-converter.nvim` is distributed under [MIT license](./LICENSE).
