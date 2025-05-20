" maping definition
function! argtextobj#Enable()
  if exists('g:argumentobject_mapping')
    execute 'xnoremap <silent> i'.g:argumentobject_mapping.' :<C-U>call <SID>MotionArgument(1, 1, 0)<CR>'
    execute 'xnoremap <silent> a'.g:argumentobject_mapping.' :<C-U>call <SID>MotionArgument(0, 1, 0)<CR>'
    execute 'onoremap <silent> i'.g:argumentobject_mapping.' :<C-U>call <SID>MotionArgument(1, 0, 0)<CR>'
    execute 'onoremap <silent> a'.g:argumentobject_mapping.' :<C-U>call <SID>MotionArgument(0, 0, 0)<CR>'
  endif
  if exists('g:argumentobject_force_mapping')
    execute 'xnoremap <silent> i'.g:argumentobject_force_mapping.' :<C-U>call <SID>MotionArgument(1, 1, 1)<CR>'
    execute 'xnoremap <silent> a'.g:argumentobject_force_mapping.' :<C-U>call <SID>MotionArgument(0, 1, 1)<CR>'
    execute 'onoremap <silent> i'.g:argumentobject_force_mapping.' :<C-U>call <SID>MotionArgument(1, 0, 1)<CR>'
    execute 'onoremap <silent> a'.g:argumentobject_force_mapping.' :<C-U>call <SID>MotionArgument(0, 0, 1)<CR>'
  endif
endfunction

" vim: set foldmethod=marker et ts=2 sts=2 sw=2:
