command! -bang -complete=file GoBuild call gobu#GoCommand('build', '<bang>' == '!')
command! -bang -complete=file GoInstall call gobu#GoCommand('install', '<bang>' == '!')
command! -bang -complete=file GoTest call gobu#GoCommand('test', '<bang>' == '!')
command! -bang -complete=file GoFmt call gobu#GoCommand('fmt', '<bank>' == '!')

if !exists('g:gobu_max_winheight')
  let g:gobu_max_winheight = 15
endif

if !exists('g:gobu_min_winheight')
  let g:gobu_min_winheight = 5
endif

