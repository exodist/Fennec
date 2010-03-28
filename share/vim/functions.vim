function! RunFennecLine()
    let cur_line = line(".")
    exe "!FENNEC_FILE='%' FENNEC_ITEM='" . cur_line . "' prove -v -I lib t/Fennec.t"
endfunction

:map <F9> :w<cr>:! FENNEC_FILE='%' prove -v -I lib t/Fennec.t<cr>
:map <F8> :w<cr>:call RunFennecLine()<cr>

