" vim autoload file
" Filename:     pgformatter.vim
" Maintainer:   janus_wel <janus.wel.3@gmail.com>
" License:      MIT License

" preparations {{{1
" reset the value of 'cpoptions' for portability
let s:save_cpoptions = &cpoptions
set cpoptions&vim

" main {{{1
" search pg_format path
if !exists('*s:SearchPgformatter')
    function s:SearchPgformatter()
        silent let path = system('which pg_format')
        if v:shell_error == 0
            return path
        endif
        return ''
    endfunction
endif

" save cursor and screen positions
" pair up this function with s:RestorePositions
if !exists('*s:SavePositions')
    function s:SavePositions()
        " cursor pos
        let cursor = getpos('.')

        " screen pos
        normal! H
        let screen = getpos('.')

        return [screen, cursor]
    endfunction
endif

" restore cursor and screen positions
" pair up this function with s:SavePositions
if !exists('*s:RestorePositions')
    function s:RestorePositions(pos)
        " screen
        call setpos('.', a:pos[0])

        " cursor
        normal! zt
        call setpos('.', a:pos[1])
    endfunction
endif

if !exists('*s:GenerateTempfileWithExtension')
    function s:GenerateTempfileWithExtension()
        return tempname() . '.' . expand('%:e')
    endfunction
endif

function pgformatter#Modify()
    let pos = s:SavePositions()
    let saved = @z
    try
        let pgformatter_path = s:SearchPgformatter()
        if pgformatter_path == ''
            return
        endif

        let tempfile = s:GenerateTempfileWithExtension()
        silent normal! gg"zyG
        execute 'redir! > ' . tempfile
        silent echo @z
        redir END

        let command = pgformatter_path . ' ' . tempfile
        let modified = substitute(system(command), '^\n\+', '', '')
        if v:shell_error != 0
            echoerr modified
            return
        endif

        silent normal! ggVG"_d
        put =modified
        silent normal! gg"_dd
    catch
        echoerr v:exception
    finally
        let @z = saved
        call s:RestorePositions(pos)
    endtry
endfunction

" post-processings {{{1
" restore the value of 'cpoptions'
let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions

" }}}1
" vim: ts=4 sw=4 sts=0 et fdm=marker fdc=3
