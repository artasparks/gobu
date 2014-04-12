let s:gobu_name = 'GobuWindow'
let s:gobufile = substitute(tempname(), '\w\+$', s:gobu_name, '')
let s:gobu_window = -2

let s:allowed_commands = {
    \ 'build' : 1,
    \ 'run' : 1,
    \ 'install' : 1,
    \ 'test' : 1,
    \ 'fmt' : 1,
    \ }

function! gobu#GoCommand(cmd, ...) abort
  let l:go_exec = 'go'
  let l:is_appengine = 0
  if g:gobu_detect_appengine
    let l:app_yaml = findfile('app.yaml', '.;')
    if l:app_yaml == 'app.yaml'
      let l:app_yaml = expand('%:p:h') . '/' . l:app_yaml
    endif
    if !empty(l:app_yaml)
      let l:go_exec = 'goapp'
    endif
    let l:is_appengine = 1
  endif

  if a:cmd == 'run'
    call gobu#RunCurrentFile(l:go_exec)
    return
  endif

  if l:is_appengine
    let l:desired_cmd = a:cmd
    if a:cmd == 'install'
      " Install isn't supported and doesn't really make sense for appengine.
      " Thus, just do
      let l:desired_cmd = 'build'
    endif
    call s:ClearOldGobu()
    let l:full_cmd = l:go_exec . ' ' . l:desired_cmd
  else
    let l:do_recursive = a:0 >= 1 ? a:1 : 0
    call s:ClearOldGobu()
    let l:curdir = expand('%:p:h')
    let l:packcmd = 'cd ' . l:curdir . ' && ' . l:go_exec . ' list'
    let l:package = s:Trim(system(l:packcmd))
    let l:suffix = l:do_recursive == 1 ? '/...' : ''
    if l:package =~# "can't load package"
      call s:SetOutput(l:packcmd, 'list', l:package)
      return
    endif
    if !has_key(s:allowed_commands, a:cmd)
      echohl WarningMSG
      echomsg 'Unknown Go Command: ' . a:cmd
      echohl NONE
      return
    endif
    let l:full_cmd = l:go_exec . ' ' . a:cmd . ' ' . l:package . l:suffix
  endif
  call s:ApplyCommandAndSetOutput(l:full_cmd, a:cmd)
  if a:cmd ==# 'fmt'
    " edit!
  endif
  redraw
endfunction

function gobu#RunCurrentFile(go_exec) abort
  execute '!' . a:go_exec . ' run ' . expand('%')
endfunction

function s:ClearOldGobu() abort
  let l:gobu_winnum = bufwinnr(s:gobu_name)
  let l:prev_window = winnr()
  if l:gobu_winnum != -1
    let l:prev_window_view = winsaveview()
    execute l:gobu_winnum . ' wincmd w'
    close
    call winrestview(l:prev_window_view)
  endif
endfunction

function s:ApplyCommandAndSetOutput(full_cmd, cmd)
  let l:errs = system(a:full_cmd)
  call s:SetOutput(a:full_cmd, a:cmd, l:errs)
endfunction

function! s:SetOutput(full_cmd, cmd, output) abort
  let l:lines = split(s:Trim(a:output), '\n')
  if empty(l:lines) || (a:cmd ==# 'fmt' && !v:shell_error)
    echohl Type
    exe 'echomsg "Gobu: [' . a:full_cmd . '] : SUCCESS"'
    echohl NONE
    call s:ClearOldGobu()
    if a:cmd ==# 'fmt'
      " Why is this here?
      edit!
    endif
    return
  endif
  let s:oldwindow = winnr()
  let s:saved_view = winsaveview()
  call s:CreateWindow(l:lines)
  call s:SetWindowDefaults(len(l:lines))

  " Restore view in old window and return
  let s:gobu_window = winnr()
  execute s:oldwindow . ' wincmd w'
  call winrestview(s:saved_view)
  execute s:gobu_window . ' wincmd w'

  let b:executed_full_cmd = a:full_cmd
  let b:executed_cmd = a:cmd

  " Set Output
  nnoremap <buffer> q :call gobu#Quit()<CR>
  nnoremap <buffer> <CR> :call gobu#ExecuteOnWindow()<CR>
  nnoremap <buffer> R :call gobu#Rerun()<CR>
endfunction

function gobu#Quit() abort
  close
endfunction

" Rerun the command
function! gobu#Rerun() abort
  let l:last_full_command = b:executed_full_cmd
  let l:last_command = b:executed_cmd
  call gobu#Quit()
  call s:ApplyCommandAndSetOutput(l:last_full_command, l:last_command)
endfunction

function! gobu#ExecuteOnWindow() abort
  let l:curline = getline('.')
  let l:path_regex = '^\t\?\(\.\?\.\?/\?[[:alnum:]_/+-]\+\.\(go\|c\|cpp\)\):\(\d*\).*'

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
    let l:pack_pattern = '^\(ok\|FAIL\|?\)\s*\t\(.*\)\t\d\+\.\d\+.*'
    let l:pack_line_num = search(l:pack_pattern, 'nc')
    let l:pack_line = getline(l:pack_line_num)
    execute s:oldwindow . ' wincmd w'

    let l:dir = ''
    if !filereadable(l:file) && l:pack_line_num > 0
      "Assume that the reason is that we need get the directory path.
      let l:found_package = substitute(l:pack_line, l:pack_pattern, '\2', '')
      let l:dir = s:Trim(system('go list -f "{{.Dir}}" ' . l:found_package))
    endif

    " Append absolute path and try again
    let l:file = !empty(l:dir) ? l:dir . '/' . l:file : l:file
    if !filereadable(l:file)
      echohl WarningMSG
      echomsg 'Could not read file: ' . l:file
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
  execute 'bo new ' . s:gobufile
  call delete(s:gobufile)
endfunction

function! s:Trim(line)
  return substitute(a:line, '^\s*\|\(\s\|\n\)*$', '', 'g')
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
    syn match GobuFile /^\t\?\.\?\.\?\/\?[[:alnum:]_/+-]\+\.\(go\|c\|cpp\)/ nextgroup=GobuLineNumber
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
