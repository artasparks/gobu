" TODO(kashomon): Add Package completion.
command! -bang GoBuild call gobu#GoCommand('build', '<bang>' == '!')
command! -bang GoInstall call gobu#GoCommand('install', '<bang>' == '!')
command! -bang GoTest call gobu#GoCommand('test', '<bang>' == '!')
command! -bang GoFmt call gobu#GoCommand('fmt', '<bang>' == '!')
command! GoRun call gobu#GoCommand('run')

if !exists('g:gobu_max_winheight')
  let g:gobu_max_winheight = 15
endif

if !exists('g:gobu_min_winheight')
  let g:gobu_min_winheight = 5
endif

if !exists('g:gobu_detect_appengine')
  let g:gobu_detect_appengine = 1
endif
