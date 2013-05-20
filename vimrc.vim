function! RunFennecLine()
    let cur_line = line(".")
    exe "!FENNEC_TEST='" . cur_line . "' prove -v -I lib %"
endfunction
 
" Go to command mode, save the file, run the current test
:map <F8> <ESC>:w<cr>:call RunFennecLine()<cr>
:imap <F8> <ESC>:w<cr>:call RunFennecLine()<cr>
