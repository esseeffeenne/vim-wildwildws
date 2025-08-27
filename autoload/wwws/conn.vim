
func! s:intowin(kind)
    let bufnr = b:_wwws[a:kind . '_bufnr']
    let winnr = bufwinnr(bufnr)
    if winnr == -1
        " no such window
        return 0
    endif

    exec winnr . 'wincmd w'
    return 1
endfunc

func! s:appendOutput(lines)
    if s:intowin('output')
        set modifiable
        call append(line('$'), a:lines)
        call s:intowin('input')
    endif
endfunc

func! s:isReady()
    return !empty(get(b:, '_wwws', {}))
endfunc

func! wwws#conn#Open() " {{{
    call wwws#output#EnsureAvailable()

    if !s:isReady()
        return
    endif

    if type(get(b:_wwws, 'job', 'no job')) == (has('nvim') ? v:t_number : v:t_job)
        echo 'Already connected'
        return
    endif

    " gather connection params
    let params = wwws#_getParams()
    if get(params, 'uri', '') ==# ''
        return
    endif

    let outputBufNr = b:_wwws['output_bufnr']
    call s:intowin('output')
    norm! ggdG
    call s:intowin('input')

    let cmd = ['wildwildws-d', params['uri']]

    for [key, value] in items(params['headers'])
        let cmd = cmd + ['-h', key . ':' . value]
    endfor

    func! OnOutput(channel, msg) closure
        " TODO parse anything?
    endfunc

    func! OnExit(channel, exitCode) closure
        call wwws#conn#Close()
    endfunc

    let args = {
        \ 'out_mode': 'nl',
        \ 'out_modifiable': 0,
        \ 'out_io': 'buffer',
        \ 'out_buf': outputBufNr,
        \ 'err_modifiable': 0,
        \ 'err_io': 'buffer',
        \ 'err_buf': outputBufNr,
        \ 'out_cb': 'OnOutput',
        \ 'exit_cb': 'OnExit',
        \ }
    let job = (has('nvim') ? jobstart(cmd, args) : job_start(cmd, args))
    let b:_wwws['job'] = job
endfunc " }}}

func! wwws#conn#CloseFor(inputBufNr)
    " disconnect; leave the output buffer open
    let _wwws = getbufvar(a:inputBufNr, '_wwws', {})
    let job = get(_wwws, 'job', 'no job')
    if type(job) != (has('nvim') ? v:t_number : v:t_job)
        return
    endif

    if has('nvim')
	call jobstop(job)
    else
	call job_stop(job)
    endif
    unlet _wwws['job']
endfunc

func! wwws#conn#Close() " {{{
    if !s:isReady()
        " nothing to do
        return
    endif

    call wwws#conn#CloseFor(bufnr('%'))

    call s:appendOutput(['', '// Disconnected'])
endfunc " }}}

func! wwws#conn#Send(message) " {{{
    " always try to reconnect if disconnected when sending
    call wwws#conn#TryConnect()

    let job = get(b:_wwws, 'job', 'no job')
    if type(job) != (has('nvim') ? v:t_number : v:t_job)
        echo 'Not connected'
        return
    endif

    if has('nvim')
	call chansend(job, [ a:message, "\n" ])
    else
	call ch_sendraw(job, a:message . "\n")
    endif
endfunc " }}}

func! wwws#conn#TryConnect() " {{{
    if !g:wwws_connect_on_save
        return
    endif

    call wwws#output#EnsureAvailable()
    if !s:isReady()
        return
    endif

    if type(get(b:_wwws, 'job', 'no job')) == (has('nvim') ? v:t_number : v:t_job)
        " already connected
        return
    endif

    call wwws#conn#Open()
endfunc " }}}

func! wwws#conn#_closed() " {{{
    call wwws#conn#Close()

    let b:wwws_init = 0

    if !has_key(b:, '_wwws')
        " not prepped yet
        return
    endif

    let outputBufNr = b:_wwws['output_bufnr']
    if bufname(outputBufNr) !=# ''
        try
            exec 'bwipeout ' . outputBufNr
        catch /.*/
            " on an error, the output buffer doesn't exist anymore
        endtry
    endif
endfunc " }}}


