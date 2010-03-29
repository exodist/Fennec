function! RunFennecLine()
    let cur_line = line(".")
    exe "!FENNEC_FILE='%' FENNEC_ITEM='" . cur_line . "' prove -v -I lib t/Fennec.t"
endfunction

