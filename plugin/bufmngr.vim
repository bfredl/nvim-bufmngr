if !has("nvim")
    finish
end

if !has_key(g:,"bufmngr_dir")
    if exists('$XDG_RUNTIME_DIR')
        let g:bufmngr_dir = $XDG_RUNTIME_DIR."/bufmngr"
    else
        let g:bufmngr_dir = "/tmp/".$USER."_/bufmngr"
    endif
endif

if !isdirectory(g:bufmngr_dir)
    call system(['mkdir', '-p', g:bufmngr_dir])
end

if has_key(g:,"bufmngr_windowid")
    " pass
elseif exists('$WINDOWID')
    let g:bufmngr_windowid = $WINDOWID
else
    let g:bufmngr_windowid = -1
end

augroup Bufmngr
    au!
    au BufAdd,BufFilePost,FileType,BufDelete  * call bufmngr#update()
    au VimLeave * call bufmngr#vimleave()
augroup END

nnoremap <Plug>(bufmngr-receive) :<c-u>call bufmngr#receive(1)<cr>
