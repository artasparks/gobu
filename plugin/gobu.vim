" TODO(kashomon): Add Package completion.  This is already built into the base
" go-vim plugin.
command! -bang GoBuild call gobu#GoCommand('build', '<bang>' == '!')
command! -bang GoInstall call gobu#GoCommand('install', '<bang>' == '!')
command! -bang GoTest call gobu#GoCommand('test', '<bang>' == '!')
command! -bang GoFmt call gobu#GoCommand('fmt', '<bang>' == '!')
" TODO(kashomon): Add a Run command
" command! -bang -complete=file GoRun call gobu#GoCommand('run', '<bang>' == '!')

if !exists('g:gobu_max_winheight')
  let g:gobu_max_winheight = 15
endif

if !exists('g:gobu_min_winheight')
  let g:gobu_min_winheight = 5
endif

if !exists('g:gobu_detect_appengine')
  let g:gobu_detect_appengine = 1
endif
