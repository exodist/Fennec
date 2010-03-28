function! RunWorkflow()
    let my_line = search( '\s*\(test_set\s\+\|sub set_\)', 'bnWc' )
    if my_line
        let set_line = getline(my_line)
        let set_a = substitute( set_line, '^\s*\(test_set\s\+\|sub set_\)', "", "" )
        let set_name = substitute( set_a, '\s.*$', "", "" )
        exe "!script/fennec_prove % -s " . set_name
    en
endfunction

map ,ts :w<cr>:call RunSet()<cr>
map ,tc :w<cr>:call RunCase()<cr>
map ,T :w<cr>:! script/fennec_prove %<cr>
":map <F9> :w<cr>:! script/fennec_prove %<cr>
":imap <F9> <ESC>:w<cr>:! script/fennec_prove %<cr>
"FENNEC_FILE='t/Fennec.pm' FENNEC_ITEM='hello_world_group' prove -I lib -v t/Fennec.t
