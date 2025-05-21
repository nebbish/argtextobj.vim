"=============================================================================
" argtextobj.vim - Text-Object like motion for arguments
"=============================================================================
"
" Author:  Takahiro SUZUKI <takahiro.suzuki.ja@gmDELETEMEail.com>
" Version: 1.1.1 (Vim 7.1)
" Licence: MIT Licence
"
"=============================================================================
" Document: {{{1
"
"-----------------------------------------------------------------------------
" Description:
"   This plugin installes a text-object like motion 'a' (argument). You can
"   d(elete), c(hange), v(select)... an argument or inner argument in familiar
"   ways, such as 'daa'(delete-an-argument), 'cia'(change-inner-argument)
"   or 'via'(select-inner-argument).
"
"   What this script do is more than just typing
"     F,dt,
"   because it recognizes inclusion relationship of parentheses.
"
"   There is an option to descide whether the motion should go out to toplevel
"   function or not in nested function application.
"   To select arguments of the toplevel function, us capital 'A'.

"
"-----------------------------------------------------------------------------
" Installation:
"   Place this file in /usr/share/vim/vim*/plugin or ~/.vim/plugin/
"   Now text-object like argument motion 'ia', 'aa', 'iA' and 'aA' is enabled
"   by default.
"
"-----------------------------------------------------------------------------
" Options:
"   Write below in your .vimrc if you want to apply motions to the toplevel
"   function.
"     let g:argumentobject_force_toplevel = 1
"   By default, this options is set to 0, which means your operation affects
"   to the most inner level
"
"-----------------------------------------------------------------------------
" Examples:
" case 1: delete an argument
"     function(int arg1,    char* arg2="a,b,c(d,e)")
"                              [N]  daa
"     function(int arg1)
"                     [N] daa
"     function()
"             [N]
"
" case 2: delete inner argument
"     function(int arg1,    char* arg2="a,b,c(d,e)")
"                              [N]  cia
"     function(int arg1,    )
"                          [I]
"
" case 3: regular argument recognition ('_a')
"     function(1, (20*30)+40, somefunc2(3, 4))
"                   [N]  cia
"     function(1, , somefunc2(3, 4))
"                [I]
"     function(1, (20*30)+40, somefunc2(3, 4))
"                                      [N]  caa
"     function(1, (20*30)+40, somefunc2(4))
"                                      [I]
"
" case 4: smart argument recognition ('_A')
"     function(1, (20*30)+40, somefunc2(3, 4))
"                   [N]  ciA
"     function(1, , somefunc2(3, 4))
"                [I]
"     function(1, (20*30)+40, somefunc2(3, 4))
"                                      [N]  caA
"     function(1, (20*30)+40)
"                          [I]
"
"-----------------------------------------------------------------------------
" ToDo:
"   - do nothing on null parentheses '()'
"
"-----------------------------------------------------------------------------
" ChangeLog:
"   1.2.0:
"     - removed g:argumentobject_force_toplevel
"     - replaced with 'a' and 'A' the equivalent of option set to 0 and 1
"
"   1.1.1:
"     - debug (stop beeping on using text objects). Thanks to Nadav Samet.
"
"   1.1.unreleased:
"     - support for commas in <..> (for cpp templates)
"
"   1.1:
"     - support for commas in quoted string (".."), array ([..])
"       do nothing outside a function declaration/call
"
"   1.0:
"     - Initial release
" }}}1
"=============================================================================

if exists('loaded_argtextobj') || &cp || version < 700
  finish
endif
let loaded_argtextobj = 1

" option. sets the mapping to use for this textobject
let g:argumentobject_mapping =
  \ get(g:, 'argumentobject_mapping', 'a')
let g:argumentobject_force_mapping =
  \ get(g:, 'argumentobject_force_mapping', 'A')


xnoremap <silent> <Plug>(argtextobj_ia) :<C-U>call argtextobj#MotionArgument(1, 1, 0)<CR>
xnoremap <silent> <Plug>(argtextobj_aa) :<C-U>call argtextobj#MotionArgument(0, 1, 0)<CR>
onoremap <silent> <Plug>(argtextobj_ia) :<C-U>call argtextobj#MotionArgument(1, 0, 0)<CR>
onoremap <silent> <Plug>(argtextobj_aa) :<C-U>call argtextobj#MotionArgument(0, 0, 0)<CR>
xnoremap <silent> <Plug>(argtextobj_iA) :<C-U>call argtextobj#MotionArgument(1, 1, 1)<CR>
xnoremap <silent> <Plug>(argtextobj_aA) :<C-U>call argtextobj#MotionArgument(0, 1, 1)<CR>
onoremap <silent> <Plug>(argtextobj_iA) :<C-U>call argtextobj#MotionArgument(1, 0, 1)<CR>
onoremap <silent> <Plug>(argtextobj_aA) :<C-U>call argtextobj#MotionArgument(0, 0, 1)<CR>

if ! hasmapto('<Plug>(argtextobj_ia)', 'x')
  xmap ia <Plug>(argtextobj_ia)
endif
if ! hasmapto('<Plug>(argtextobj_aa)', 'x')
  xmap aa <Plug>(argtextobj_aa)
endif
if ! hasmapto('<Plug>(argtextobj_ia)', 'o')
  omap ia <Plug>(argtextobj_ia)
endif
if ! hasmapto('<Plug>(argtextobj_aa)', 'o')
  omap aa <Plug>(argtextobj_aa)
endif
if ! hasmapto('<Plug>(argtextobj_iA)', 'x')
  xmap iA <Plug>(argtextobj_iA)
endif
if ! hasmapto('<Plug>(argtextobj_aA)', 'x')
  xmap aA <Plug>(argtextobj_aA)
endif
if ! hasmapto('<Plug>(argtextobj_iA)', 'o')
  omap iA <Plug>(argtextobj_iA)
endif
if ! hasmapto('<Plug>(argtextobj_aA)', 'o')
  omap aA <Plug>(argtextobj_aA)
endif

" vim: set foldmethod=marker et ts=2 sts=2 sw=2:
