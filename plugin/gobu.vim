command! -bang -complete=file GoBu call gobu#GoBuilder('build')
command! -bang -complete=file GoTe call gobu#GoBuilder('test', '<bang>')

if !exists('g:gobu_max_winheight')
  let g:gobu_max_winheight = 15
endif

if !exists('g:gobu_min_winheight')
  let g:gobu_min_winheight = 5
endif

