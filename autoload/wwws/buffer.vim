func! wwws#buffer#_SendWrapper(motion)
	let reg = '"'

	let cursor = getcurpos()
	let sel_save = &selection
	let &selection = 'inclusive'
	let cb_save  = &clipboard
	set clipboard-=unnamed clipboard-=unnamedplus
	let reg_save = getreg(reg)
	let reg_type = getregtype(reg)

	" select the paragraph and get its text
	silent exe 'normal! "' . reg . a:motion
	let toSend = getreg(reg)

	" restore settings
	call setreg(reg, reg_save, reg_type)
	let &clipboard = cb_save
	let &selection = sel_save
	call setpos('.', cursor)

	" send the value
	call wwws#conn#Send(toSend)
endfunc

func! wwws#buffer#SendParagraph()
	call wwws#buffer#_SendWrapper('GVggy')
endfunc

func! wwws#buffer#SendLine()
	call wwws#buffer#_SendWrapper('yy')
endfunc

func! wwws#buffer#SendDeleteParagraph()
	call wwws#buffer#_SendWrapper('GVggd')
endfunc

func! wwws#buffer#SendHeadless()
	call wwws#buffer#_SendWrapper('GVgg' . b:_headersSize . 'jy')
endfunc

func! wwws#buffer#SendDeleteHeadless()
	call wwws#buffer#_SendWrapper('GVgg' . b:_headersSize . 'jd')
endfunc

