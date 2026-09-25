# Third-Party Notices

Parts of the desktop shell and application styling in this repository are
adapted from an MIT-licensed desktop configuration.

## MIT License

Copyright (c) 2026 43PR

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Kitty Theme Library

`config/kitty/themes/*.conf` are vendored color schemes from the MIT-licensed
kitty-themes collection, ported from iTerm2-Color-Schemes. The upstream notice is
kept at `config/kitty/themes/LICENSE.md`.

Copyright (c) 2019 Fabrizio Destro <fabrizio@destro.dev>

## Waybar Theme Library

`config/waybar/themes/*.css` are vendored from the MIT-licensed waybar-themes
collection, and `config/waybar/themes/*.jsonc` are layouts generated from the
same collection's configs by `scripts/build-bar-layouts.py`. For the stylesheets
the only edits are: the `@import "../omarchy/current/theme/waybar.css"` line is
replaced by `@define-color background @bg;` and `@define-color foreground @fg;`
so the themes follow the generated kome palette, and selectors naming the
omarchy menu module (`custom-omarchy*`) are removed by
`scripts/strip-omarchy-css.py`. For the layouts the module list, order, heights,
margins, formats, and tooltips are upstream; omarchy-only modules are dropped,
omarchy click handlers are rewritten to the equivalent kome script, and the
modules needing `wttrbar` or `waybar-module-pacman-updates` get an `exec-if`
guard. `config/waybar/scrolling-mpris.py` is V7.2b's scrolling MPRIS script,
credited to Mezutelni in the upstream README. The upstream notice is kept at
`config/waybar/themes/LICENSE.md`.

Copyright (c) 2025 drdeltree
