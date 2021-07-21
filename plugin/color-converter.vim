if !has('nvim-0.5')
    echoerr 'color-converter.nvim requires at least nvim-0.5. Please update or uninstall'
    finish
endif

if exists('g:loaded_color_converter') | finish | endif

nnoremap <Plug>ColorConvertCycle :lua require('color-converter').cycle()<CR>
nnoremap <Plug>ColorConvertHEX :lua require('color-converter').to_hex()<CR>
nnoremap <Plug>ColorConvertRGB :lua require('color-converter').to_rgb()<CR>
nnoremap <Plug>ColorConvertHSL :lua require('color-converter').to_hsl()<CR>

let s:save_cpo = &cpo
set cpo&vim

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_color_converter = 1
