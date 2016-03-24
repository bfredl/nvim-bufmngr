function! s:pidpath(pid) abort
    return  g:bufmngr_dir.'/'.a:pid.'.mpack'
endfunction

function! bufmngr#write(pid, data) abort
    call writefile(msgpackdump(a:data), s:pidpath(a:pid), 'b')
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
    call delete(s:pidpath(getpid()))
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
        let data =  msgpackparse(readfile(f, 'b'))
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

