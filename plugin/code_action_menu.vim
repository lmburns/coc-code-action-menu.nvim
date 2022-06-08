function! s:CodeActionFromSelected(type)
  call luaeval("require('coc_code_action_menu').open_code_action_menu(_A)", a:type)
endfunction

vnoremap <silent> <Plug>(coc-codeaction-selected-menu) \
    <Cmd>call luaeval("require('coc_code_action_menu').open_code_action_menu(_A)", visualmode())<CR>
nnoremap <silent> <Plug>(coc-codeaction-selected-menu) \
    <Cmd>set operatorfunc=<SID>CodeActionFromSelected<CR>g@

nnoremap <Plug>(coc-codeaction-menu)             <Cmd>lua require('coc_code_action_menu').open_code_action_menu('')<CR>
nnoremap <Plug>(coc-codeaction-line-menu)        <Cmd>lua require('coc_code_action_menu').open_code_action_menu('line')<CR>
nnoremap <Plug>(coc-codeaction-cursor-menu)      <Cmd>lua require('coc_code_action_menu').open_code_action_menu('cursor')CR>
