let s:gobufile = substitute(tempname(), '\w\+$', 'GobuWindow', '')
let s:gobu_window = -2

let s:allowed_commands = {
    \ 'build' : 1,
    \ 'install' : 1,
    \ 'test' : 1,
    \ 'fmt' : 1,
    \ }

function! gobu#GoCommand(cmd, ...) abort
  let l:do_recursive = a:0 >= 1 ? a:1 : 0
  if bufexists(s:gobufile) && bufloaded(s:gobufile)
    call s:ClearOldGobu()
  endif
  let l:curdir = expand('%:p:h')
  let l:package = s:Trim(system('cd ' . l:curdir . ' && go list'))
  let l:suffix = l:do_recursive == 1 ? '/...' : ''
  if !has_key(s:allowed_commands, a:cmd)
    echohl WarningMSG
    echomsg 'Unknown Go Command: ' . a:cmd
    echohl NONE
    return
  endif
  let l:full_cmd = 'go ' . a:cmd . ' ' . l:package . l:suffix
  call s:SetOutput(system(l:full_cmd), l:full_cmd, a:cmd)
endfunction

function s:ClearOldGobu()
  let l:prev_window = winnr()
  let l:prev_window_view = winsaveview()
  exe s:gobu_window . ' wincmd w'
  close
  exe l:prev_window . ' wincmd w'
  call winrestview(l:prev_window_view)
endfunction

function! s:SetOutput(errs, full_cmd, cmd)
  let l:lines = split(s:Trim(a:errs), '\n')
  if empty(l:lines)
    echohl Type
    exe 'echomsg "Gobu: [' . a:full_cmd . '] : SUCCESS"'
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

  let b:executed_cmd = a:cmd

  nnoremap <buffer> q :q<CR>
  nnoremap <buffer> <CR> :call gobu#ExecuteOnWindow()<CR>
endfunction

function! gobu#ExecuteOnWindow()
  let l:curline = getline('.')
  let l:path_regex = '^\t\?\(\.\?/\?[[:alnum:]_/+-]\+\.\(go\|c\|cpp\)\):\(\d*\).*'

  if l:curline =~ l:path_regex
    let l:file = substitute(l:curline, l:path_regex, '\1', '')
    let l:lnum = substitute(l:curline, l:path_regex, '\3', '')

    " If the file path isn't absolute, we need to look up the directory for
    " the current.  The file path will be absolute in the case of a panic, but
    " not in the case of build or test runs.
    "
    " For this, we search done from the current position to find somthing that
    " looks like a package.  Then, we use 'go list' to determine the directory
    " path.
    let l:dir = ''
    if !filereadable(l:file)
      "Assume that the reason is that we need get the directory path.
      let l:pack_pattern = '^\(ok\|FAIL\|?\)\s*\t\(.*\)\t\d\+\.\d\+.*'
      let l:pack_line_num = search(l:pack_pattern, 'nc')
      let l:pack_line = getline(l:pack_line_num)
      let l:found_package = substitute(l:pack_line, l:pack_pattern, '\2', '')
      let l:dir = s:Trim(system('go list -f "{{.Dir}}" ' . l:found_package))
    endif

    exe s:oldwindow . ' wincmd w'
    " Append absolute path and try again
    let l:file = !empty(l:dir) ? l:dir . '/' . l:file : l:file
    if !filereadable(l:file)
      echohl WarningMSG
      echomsg 'Couldn't read file: ' . l:file
      echohl NONE
    endif
    exe 'edit ' . l:file

    " Set position
    let l:curpos = getpos('.')
    let l:curpos[1] = l:lnum + 0
    call setpos('.', l:curpos)
    normal! zz
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
    syn match GobuSpecial /^?/

    hi def link GobuFile Directory
    hi def link GobuLineNumber Keyword
    hi def link GobuKeyword Type
    hi def link GobuPass Type
    hi def link GobuTime Keyword
    hi def link GobuSpecial Special
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

function! s:Trim(line)
  return substitute(a:line, '^\s*\|\(\s\|\n\)*$', '', 'g')
endfunction
