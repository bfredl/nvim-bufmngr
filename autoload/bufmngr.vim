function! s:path(pid) abort
    return  g:bufmngr_dir.'/'.a:pid.'.mpack'
endfunction

function! bufmngr#write(id, data) abort
    call writefile(msgpackdump(a:data), s:path(a:id), 'b')
endfunction

function! bufmngr#local_buflist() abort
    let blist = []
    for buf in range(1, bufnr('$'))
        if !buflisted(buf)
            continue
        endif
        let bt = getbufvar(buf, '&buftype')
        if match(bt, "help\\|quickfix\\|nofile") >= 0
            continue
        endif
        let name = fnamemodify(bufname(buf), ":p:~")
        call add(blist, {'nr': buf, 'name': name, 'ft':getbufvar(buf, '&ft')})
    endfor
    return blist
endfunction

function! bufmngr#update() abort
    let pid = getpid()
    let buflist = bufmngr#local_buflist()
    let address = v:servername
    call bufmngr#write(pid, [g:bufmngr_windowid, address, buflist])
endfunction

function! bufmngr#vimleave() abort
    call delete(s:path(getpid()))
endfunction

function! bufmngr#read() abort
    let instances = {}
    let files = glob(g:bufmngr_dir."/[0-9]*.mpack", 1, 1)
    for f in files
        let tail = fnamemodify(f, ":t")
        let pid = matchstr(tail, "\\v[0-9]+\\ze\\.mpack$")
        if !isdirectory("/proc/".pid)
            continue
        endif
        let data = msgpackparse(readfile(f, 'b'))
        let instances[str2nr(pid)] = data
    endfor
    return instances
endfunction

function! bufmngr#buflist() abort
    call bufmngr#update()
    let instances = bufmngr#read()
    let buffers = []
    for [pid, i] in items(instances)
        let [windowid, address, bufs] = i
        for b in bufs
            call add(buffers, extend(b,{
                \ 'windowid' : windowid,
                \ 'pid' : pid,
                \ 'address' : address,
                \}))
        endfor
    endfor
    return buffers
endfunction

function! bufmngr#activate(buf) abort
    let islocal = a:buf.pid == getpid()
    if !islocal
        if a:buf.windowid != -1
            call system(['wmctrl', '-i', '-a', a:buf.windowid])
        endif
        if g:bufmngr_is_switcher
            "doesn't work :(
            "call system(['wmctrl', '-i', '-r', g:bufmngr_windowid, '-b', 'add,hidden'])
            call system(['xdotool', 'windowminimize', g:bufmngr_windowid])
        end
        " TODO: rpc!
        call bufmngr#write('activate', [a:buf])
    else
        call bufmngr#activate_local(a:buf.nr, 1)
    end
endfunction

" split = 0 open in this window
" split = 1 jump to window, otherwise open in this window
" split = 2 jump to window or new split
function! bufmngr#activate_local(bufnr, split) abort
    let win = bufwinnr(a:bufnr)
    if bufnr(".") == a:bufnr
        return 1
    elseif win != -1 && a:split > 0
        execute win.'wincmd w'
    else
        if a:split > 1
            split
        endif
        execute 'b'.a:bufnr
    endif
endfunction


function! bufmngr#receive(split) abort
    let [buf] = msgpackparse(readfile(s:path('activate'), 'b'))
    if buf.pid == getpid()
        call bufmngr#activate_local(buf.nr, a:split)
    end
endfunction
