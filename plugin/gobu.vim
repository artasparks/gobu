command! -bang -complete=file GoBu call gobu#GoBuilder('build')
command! -bang -complete=file GoTe call gobu#GoBuilder('test', '<bang>')

if !exists('g:gobu_max_winheight')
  let g:gobu_max_winheight = 15
endif

if !exists('g:gobu_min_winheight')
  let g:gobu_min_winheight = 5
endif

let s:gobufile = substitute(tempname(), '\w\+$', 'GobuWindow', '')
let s:gobu_window = -2

function! gobu#GoBuilder(type, ...) abort
  let l:do_recursive = a:0 >= 1 ? a:1 : 0
  if bufexists(s:gobufile) && bufloaded(s:gobufile)
    call s:ClearOldGobu()
  endif
  let package = substitute(expand('%:h'), '.*/src/\(.*\)', '\1', '')
  let l:suffix = l:do_recursive ? '/...' : ''
  if a:type ==# 'test'
    call s:SetErrors(system('go test ' . package . l:suffix), 'test')
  else
    call s:SetErrors(system('go install ' . package . l:suffix), 'build')
  endif
endfunction

function s:ClearOldGobu()
  let l:prev_window = winnr()
  let l:prev_window_view = winsaveview()
  exe s:gobu_window . ' wincmd w'
  close
  exe l:prev_window . ' wincmd w'
  call winrestview(l:prev_window_view)
endfunction

function! s:SetErrors(errs, type)
  let l:lines = split(substitute(a:errs, '^\s*\|\s*$', '', 'g'), '\n')
  if empty(l:lines)
    echohl Type
    exe 'echomsg "Gobu ' . a:type . ':PASS"'
    echohl NONE
    return
  endif
  let s:oldwindow = winnr()
  let s:saved_view = winsaveview()
  call s:CreateWindow(l:lines)
  call s:SetWindowDefaults(len(l:lines))

  " Restore view in old window and return
  let s:gobu_window = winnr()
  exe s:oldwindow . ' wincmd w'
  call winrestview(s:saved_view)
  exe s:gobu_window . ' wincmd w'

  nnoremap <buffer> q :q<CR>
  nnoremap <buffer> <CR> :call gobu#ExecuteOnWindow()<CR>
endfunction

function! gobu#ExecuteOnWindow()
  let l:curline = getline('.')
  let l:path_regex = '^\t\?\(\.\?/\?[[:alnum:]_/+-]\+\.\(go\|c\|cpp\)\):\(\d*\).*'
  if l:curline =~ l:path_regex
    let l:file = substitute(l:curline, l:path_regex, '\1', '')
    let l:lnum = substitute(l:curline, l:path_regex, '\3', '')
    exe s:oldwindow . ' wincmd w'
    exe 'edit ' . l:file
    let l:curpos = getpos('.')
    let l:curpos[1] = l:lnum + 0
    call setpos('.', l:curpos)
  endif
endfunction

function s:SetWindowDefaults(num_lines)
  cal setpos(".", [0,0,0,0])
  setlocal nonumber
  setlocal nomodifiable
  setlocal readonly
  setlocal noswapfile
  setlocal nobuflisted
  setlocal buftype=nofile
  setlocal bufhidden=delete
  call s:SetHeight(a:num_lines)
  if v:version >= 700
    setlocal cursorline
  endif
  if has('syntax')
    syn match GobuFile /^\t\?\.\?\/\?[[:alnum:]_/+-]\+\.\(go\|c\|cpp\)/ nextgroup=GobuLineNumber
    syn match GobuLineNumber /:\d\+:\?/
    syn match GobuKeyword /goroutine \d*/
    syn keyword GobuFail FAIL
    syn match GobuPass /^ok/
    syn match GobuFail /panic:/
    syn match GobuFail /runtime error/
    syn match GobuTime /\d\+\.\d\d\ds/

    hi def link GobuFile Directory
    hi def link GobuLineNumber Keyword
    hi def link GobuKeyword Type
    hi def link GobuPass Type
    hi def link GobuTime Keyword

    hi def link GobuFail WarningMSG
  endif
endfunction

function! s:SetHeight(num_lines)
  if a:num_lines < g:gobu_min_winheight
    exe 'resize ' . g:gobu_min_winheight
  elseif a:num_lines > g:gobu_max_winheight
    exe 'resize ' . g:gobu_max_winheight
  else
    exe 'resize ' . a:num_lines
  endif
  setlocal winfixheight
endfunction

function s:CreateWindow(lines)
  call writefile(a:lines, s:gobufile)
  exe 'bo new ' . s:gobufile
  call delete(s:gobufile)
endfunction
