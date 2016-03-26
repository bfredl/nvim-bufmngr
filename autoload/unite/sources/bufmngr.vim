
function! unite#sources#bufmngr#define()
  return s:source
endfunction

let s:source = {
      \ 'name' : 'bufmngr',
      \ 'description' : 'open windows',
      \ 'action_table' : {},
      \ 'default_action' : 'open',
      \}

function! s:source.gather_candidates(args, context)
    let bufs = bufmngr#buflist()
    return map(bufs, "{
        \ 'word' : v:val.name,
        \ 'action__buf' : v:val
        \ }")
endfunction

let s:source.action_table.open = {
      \ 'description' : 'move to this window',
      \ }
function! s:source.action_table.open.func(candidate)
    call bufmngr#activate(a:candidate.action__buf)
endfunction
