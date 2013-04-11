command! -bang -complete=file GoBu call gobu#GoBuilder('build')
command! -bang -complete=file GoTe call gobu#GoBuilder('test')

function! gobu#GoBuilder(type)
  let package = substitute(
      \ expand('%:h')
      \ '.*/src/\(.*\)',
      \ '\1',
      \ '')
  if a:type ==# 'test'
    let build_out = system('go test' . package)
    if build_out !~ '\[build failed\]'
      call s:SetErrors(build_out)
    else
      call s:SetErrors(system('go install ' . package))
    endif
  else
    call s:SetErrors(system('go install ' . package))
  endif
  redraw!
endfunction

function! s:SetErrors(errs)
  let out = split(substitute(a:errs, '^\s*\|\s*$', '', 'g'), '\n')
  call filter(out, 'v:val =~ "\\w\\+\\.go:\\d\\+:"')
  if len(out) == 0
    echo 'No go errors.'
    cclose
    return
  endif
  let win_height = len(out)
  if win_height < 5
    let win_height = 5
  elseif win_height > 24
    let win_height = 5
  else
    let win_height = win_height + 1
  endif
  cexpr out
  exe 'botright copen ' . win_height
  setl winfixheight
  setl cursorline
  cc
endfunction
