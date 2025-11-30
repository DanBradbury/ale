" Author: Dan Bradbury - https://github.com/DanBradbury
" Description: Vinter, a code style analyzer for vim9script files

call ale#Set('vim_vinter_executable', 'vinter')
call ale#Set('vim_vinter_options', '')

function! ale_linters#vim#vinter#GetCommand(buffer) abort
    let l:executable = ale#Var(a:buffer, 'vim_vinter_executable')

    return ale#vim#EscapeExecutable(l:executable, 'vinter') . ' --format json .'
endfunction

function! ale_linters#vim#vinter#GetType(severity) abort
    if a:severity is? 'convention'
    \|| a:severity is? 'warning'
    \|| a:severity is? 'refactor'
        return 'W'
    endif

    return 'E'
endfunction

" Handle output from rubocop and linters that depend on it (e.b. standardrb)
function! ale_linters#vim#vinter#HandleOutput(buffer, lines) abort
    try
        let l:errors = json_decode(join(a:lines, "\n"))
    catch
        return []
    endtry

    if !has_key(l:errors, 'summary')
    \|| l:errors['summary']['offense_count'] == 0
    \|| empty(l:errors['files'])
        return []
    endif

    let l:output = []

    for l:error in l:errors['files'][0]['offenses']
        let l:start_col = l:error['location']['column'] + 0
        call add(l:output, {
        \   'lnum': l:error['location']['line'] + 0,
        \   'col': l:start_col,
        \   'end_col': l:start_col + l:error['location']['length'] - 1,
        \   'code': l:error['cop_name'],
        \   'text': l:error['message'],
        \   'type': 'E'
        \})
    endfor

    return l:output
endfunction

call ale#linter#Define('vim', {
\   'name': 'vinter',
\   'executable': 'vinter',
\   'command': '%e %t --format=json',
\   'callback': 'ale_linters#vim#vinter#HandleOutput',
\   'read_buffer': 0,
\})
