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

"if exists('loaded_argtextobj') || v:version < 701
"  finish
"endif
"let loaded_argtextobj = 1

function! s:GetOutOfDoubleQuote()
  " get out of double quoteed string (one letter before the beginning)
  let line = getline('.')
  let pos_save = getpos('.')
  let mark_b = getpos("'<")
  let mark_e = getpos("'>")
  let repl='_'
  let did_modify = 0
  if getline('.')[getpos('.')[2]-1]=='_'
    let repl='?'
  endif

  while 1
    exe 'silent! normal! ^va"'
    normal! :\<ESC>\<CR>
    if getpos("'<")==getpos("'>")
      break
    endif
    exe 'normal! gvr' . repl
    let did_modify = 1
  endwhile

  call setpos('.', pos_save)
  if getline('.')[getpos('.')[2]-1]==repl
    " in double quote
    if did_modify
      silent undo
      call setpos('.', pos_save)
    endif
    if getpos('.')==getpos("'<")
      call <SID>MoveLeft(1)
    else
      normal! F"
    endif
  elseif did_modify
    silent undo
    call setpos('.', pos_save)
  endif
endfunction

function! s:GetOuterFunctionParenthesis(force_toplevel)
  let pos_save = getpos('.')
  let rightup_before = pos_save
  silent! normal! [(
  let rightup_p = getpos('.')
  while rightup_p != rightup_before
    if ! a:force_toplevel && getline('.')[getpos('.')[2]-1-1] =~ '[a-zA-Z0-9_ ]'
      " found a function
      break
    endif
    let rightup_before = rightup_p
    silent! normal! [(
    let rightup_p = getpos('.')
  endwhile
  call setpos('.', pos_save)
  return rightup_p
endfunction

function! s:GetPair(pos)
  let pos_save = getpos('.')
  call setpos('.', a:pos)
  normal! %
  call <SID>MoveLeft(1)
  let pair_pos = getpos('.')
  call setpos('.', pos_save)
  return pair_pos
endfunction

function! s:GetInnerText(r1, r2)
  let pos_save = getpos('.')
  let cb_save = &clipboard
  set clipboard= " Avoid clobbering the selection and clipboard registers.
  let reg_save = @@
  let regtype_save = getregtype('"')
  call setpos('.', a:r1)
  call <SID>MoveRight(1)
  normal! v
  call setpos('.', a:r2)
  if &selection ==# 'exclusive'
    call <SID>MoveRight(1)
  endif
  normal! y
  let val = @@
  call setpos('.', pos_save)
  call setreg('"', reg_save, regtype_save)
  let &clipboard = cb_save
  return val
endfunction

function! s:GetPrevCommaOrBeginArgs(arglist, offset)
  let commapos = strridx(a:arglist, ',', a:offset)
  return max([commapos+1, 0])
endfunction

function! s:GetNextCommaOrEndArgs(arglist, offset, count)
  let commapos = a:offset - 1
  let c = a:count
  while c > 0
    let commapos = stridx(a:arglist, ',', commapos + 1)
    if commapos == -1
      if c > 1
        execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
      endif
      return strlen(a:arglist)-1
    endif
    let c -= 1
  endwhile
  return commapos-1
endfunction

function! s:MoveToNextNonSpace()
  let oldp = getpos('.')
  let moved = 0
  while getline('.')[getpos('.')[2]-1] =~ '\s'
    call <SID>MoveRight(1)
    if oldp == getpos('.')
      break
    endif
    let oldp = getpos('.')
    let moved += 1
  endwhile
  return moved
endfunction

function! s:MoveLeft(num)
  if a:num>0
    " Use the motion that is by default in the 'whichwrap' setting
    " (i.e. '<bs>' instead of 'h')
    exe "normal! " . a:num . "\<bs>"
  endif
endfunction

function! s:MoveRight(num)
  if a:num>0
    " Use the motion that is by default in the 'whichwrap' setting
    " (i.e. '<space>' instead of 'l')
    exe "normal! " . a:num . "\<space>"
  endif
endfunction

function! s:MotionArgument(inner, visual, force_toplevel)
  let cnt = v:count1
  let current_c = getline('.')[getpos('.')[2]-1]
  if current_c==',' || current_c=='('
    call <SID>MoveRight(1)
  endif

  " get out of "double quoted string" because [( does not take effect in it
  call <SID>GetOutOfDoubleQuote()

  let rightup      = <SID>GetOuterFunctionParenthesis(a:force_toplevel)       " on (
  if getline(rightup[1])[rightup[2]-1]!='('
    " not in a function declaration nor call
    execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
    return
  endif
  let rightup_pair = <SID>GetPair(rightup)                    " before )
  let arglist_str  = <SID>GetInnerText(rightup, rightup_pair) " inside ()
  let arglist_sub  = arglist_str
  " cursor offset from rightup
  if getpos('.')[1] == rightup[1]
    let offset = getpos('.')[2] - rightup[2] - 1
  else
    let offset = 0
    " NOTE: this calculation includes each newline as +1
    " Because the calculation of how far to move left & right
    " is done against the *extracted text* which contains
    " newlines, and those motions start from the offset we
    " calculate here. Even ff=dos files' newlines are just
    " "\n" in the extracted string.
    for i in range(rightup[1], getpos('.')[1])
      if i == rightup[1]
        let offset += len(getline(i)) - rightup[2]
      elseif i == getpos('.')[1]
        let offset += getpos('.')[2]
      else
        let offset += len(getline(i)) + 1
      endif
    endfor
  endif

  " replace all parentheses and commas inside them to '_'
  let arglist_sub = substitute(arglist_sub, "'".'\([^'."'".']\{-}\)'."'", '\="(".substitute(submatch(1), ".", "_", "g").")"', 'g') " replace '..' => (__)
  let arglist_sub = substitute(arglist_sub, '\[\([^'."'".']\{-}\)\]', '\="(".substitute(submatch(1), ".", "_", "g").")"', 'g')     " replace [..] => (__)
  let arglist_sub = substitute(arglist_sub, '<\([^'."'".']\{-}\)>', '\="(".substitute(submatch(1), ".", "_", "g").")"', 'g')       " replace <..> => (__)
  let arglist_sub = substitute(arglist_sub, '"\([^'."'".']\{-}\)"', '(\1)', 'g') " replace ''..'' => (..)
  """echo 'transl quotes: ' . arglist_sub
  while stridx(arglist_sub, '(')>=0 && stridx(arglist_sub, ')')>=0
    let arglist_sub = substitute(arglist_sub , '(\([^()]\{-}\))', '\="<".substitute(submatch(1), ",", "_", "g").">"', 'g')
    """echo 'sub single quot: ' . arglist_sub
  endwhile

  " the beginning/end of this argument
  let thisargbegin = <SID>GetPrevCommaOrBeginArgs(arglist_sub, offset)
  let thisargend   = <SID>GetNextCommaOrEndArgs(arglist_sub, offset, cnt)

  " function(..., the_nth_arg, ...)
  "             [^left]    [^right]
  " NOTE: because our above offset calculations where done using newlines in
  " the text, AND, because our "motion" functions IGNORE newlines, we need to
  " remove the newlines from the final motion numbers.
  let left  = offset - thisargbegin - count(arglist_sub[thisargbegin:offset], "\n")
  let right = thisargend - thisargbegin - count(arglist_sub[offset:thisargend], "\n")

  """echo 'on(='. rightup[2] . ' before)=' . rightup_pair[2]
  """echo arglist_str
  """echo arglist_sub
  """echo offset
  """echo 'argbegin='. thisargbegin . '  argend='. thisargend
  """echo 'left=' . left . '  right='. right

  let delete_trailing_space = 0
  if a:inner
    " ia
    call <SID>MoveLeft(left)
    let right -= <SID>MoveToNextNonSpace()
  else
    " aa
    if thisargbegin==0 && thisargend==strlen(arglist_sub)-1
      " only single argument
      call <SID>MoveLeft(left)
    elseif thisargbegin==0
      " head of the list (do not delete '(')
      call <SID>MoveLeft(left)
      let right += 1
      let delete_trailing_space = 1
    else
      " normal or tail of the list
      call <SID>MoveLeft(left+1)
      let right += 1
    endif
  endif

  exe 'normal! v'

  call <SID>MoveRight(right)
  if delete_trailing_space
    call <SID>MoveRight(1)
    call <SID>MoveToNextNonSpace()
    call <SID>MoveLeft(1)
  endif

  if &selection ==# 'exclusive'
    call <SID>MoveRight(1)
  endif
endfunction

" maping definition
vnoremap <silent> ia :<C-U>call <SID>MotionArgument(1, 1, 0)<CR>
vnoremap <silent> aa :<C-U>call <SID>MotionArgument(0, 1, 0)<CR>
onoremap <silent> ia :<C-U>call <SID>MotionArgument(1, 0, 0)<CR>
onoremap <silent> aa :<C-U>call <SID>MotionArgument(0, 0, 0)<CR>
vnoremap <silent> iA :<C-U>call <SID>MotionArgument(1, 1, 1)<CR>
vnoremap <silent> aA :<C-U>call <SID>MotionArgument(0, 1, 1)<CR>
onoremap <silent> iA :<C-U>call <SID>MotionArgument(1, 0, 1)<CR>
onoremap <silent> aA :<C-U>call <SID>MotionArgument(0, 0, 1)<CR>

" option. turn 1 to search the most toplevel function
let g:argumentobject_force_toplevel = 0

" vim: set foldmethod=marker et ts=2 sts=2 sw=2:
