" check j2p2j exists
if !executable("j2p2j")
    echoerr "j2p2j not found"
    finish
endif

" create view
function! vimjupyter()
  let l:original_file = substitute(expand('%:p'), '\ ', '\\ ', 'g')
  let l:proxy_file = tempname() . "_" .expand('%:t')

  " convert ipynb -> py 
  " and save in proxy file
  call system('j2p2j ' . l:original_file . " " . l:proxy_file . ' --mode j2p')

  " Open proxy file
  silent execute 'edit' l:proxy_file

  " Save references to proxy file and the original
  let b:original_file = l:original_file
  let b:proxy_file = l:proxy_file

  " Close original file (it won't be edited directly)
  silent execute ':bd' l:original_file

  " set filetype to python
  set filetype=python
endfunction

" Update ipynb when saving buffer
function! vimJupyter#updateNotebook()
  function! s:out_cb(ch, msg)
      echo a:msg
  endfunction

  let l:command = ['j2p2j', b:proxy_file, b:original_file, '--mode', 'p2j']
  let s:save_flag = job_start(
        \ l:command, 
        \ {'err_cb': function('s:out_cb'),
        \ 'out_cb': function('s:out_cb')})
endfunction

function! vimJupyter#waitUntilSaved()
    if exists('s:save_flag') && s:save_flag !=? ''
      while job_status(s:save_flag) !~? 'dead'
      endwhile
    endif
endfunction

" commands
command! -nargs=0 vimJupyterUpdate call vimJupyter#updateNotebook()

" DEFINE AUTOCOMMANDS
augroup vimJupyterAutoCommands
    au!
    autocmd BufReadPost *.ipynb call vimjupyter()
    autocmd BufNewFile *.ipynb call vimjupyter()
    autocmd BufWritePost *.ipynb :vimJupyterUpdate
    autocmd VimLeavePre *.ipynb call vimJupyter#waitUntilSaved()
augroup END
