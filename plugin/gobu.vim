command GoBuilder call gobu#GoBuilder()

function! gobu#GoBuilder()
  let file_name = expand('%')
  let dir = substitute(expand('%:p:h'), getcwd(), '', '')

  if file_name =~ '_test\.go$'
    let build_out = system('go test' . dir)
    if build_out !~ '\[build failed\]'
      call s:SetErrors(build_out)
    else
      call s:SetErrors(system('go build ' . dir))
    endif
  else
    call s:SetErrors(system('go build ' . dir))
  endif
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
  elseif winheight > 24
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
