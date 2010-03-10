function! RunSet()
    let my_line = search( '\s*\(test_set\s\+\|sub set_\)', 'bnWc' )
    if my_line
        let set_line = getline(my_line)
        let set_a = substitute( set_line, '^\s*\(test_set\s\+\|sub set_\)', "", "" )
        let set_name = substitute( set_a, '\s.*$', "", "" )
        exe "!script/fennec_prove % -s " . set_name
    en
endfunction

function! RunCase()
    let my_line = search( '\s*\(test_case\s\+\|sub case_\)', 'bnWc' )
    if my_line
        let case_line = getline(my_line)
        let case_a = substitute( case_line, '^\s*\(test_case\s\+\|sub case_\)', "", "" )
        let case_name = substitute( case_a, '\s.*$', "", "" )
        exe "!script/fennec_prove % -c " . case_name
    en
endfunction

map ,ts :w<cr>:call RunSet()<cr>
map ,tc :w<cr>:call RunCase()<cr>
map ,T :w<cr>:! script/fennec_prove %<cr>
:map <F9> :w<cr>:! script/fennec_prove %<cr>
:imap <F9> <ESC>:w<cr>:! script/fennec_prove %<cr>
