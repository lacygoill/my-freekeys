if exists('g:loaded_freekeys')
  finish
endif
let g:loaded_freekeys = 1
" TODO: "{{{

" - look at all the 'default_mappings' mappings, and see if some of them
"   are useless, or only useful with a count.
"   If there are, add them as free keys (with warnings).
"   Example:  `go`, useful with a count, useless without
"
"   I've removed `go` from the default keys (inside `s:default_mappings()`),
"   but I haven't added a warning for it. To do.
"
" - improve help:
"
"           - readibility
"           - sections by mode
"           - integrate most of the comments which are in this file,
"             and in ~/mappings.md, and in our notes
"
" - add `op+*`, `op+#` but with warning.
"
"   Although, these syntaxes are valid, I'm not sure one would use them often
"   because `*` and `#` are much more unpredictable than `2j` or `3k` for example.
"   We don't systematically see all the text between current position and the
"   next occurrence of the current word.
"   Besides, aren't `op+n`, `op+N` synonym syntaxes?
"
"   check if there are other unpredictable `operator + motions` combinations like
"   `c*`, `!*`, which would be rarely used; add them with warnings
"
"   Also, I think, ` `, `CR`, `BS` could be used after an op.
"   We wouldn't lose anything. There must be synonym syntaxes. To be verified.
"
" - add `<+char`, `>+char` in visual mode
"
" - add other control characters in normal mode
"   C-k is not the only one, for example C-j is a synonym for `j`
"
" - add tricks in the help taken from ~/mappings.md and from our notes
"   (section mapping-lhs)
"
" - insert / visual / Ex / operator pending syntaxes
"
" - after executing `:FK -nomapcheck`, if we hit `gh` twice, a Leader is added
"   Specifically, `CTRL-Space` becomes `CTRL-Leader`.
"
" - Can we use the same command (x, a, i, m, o, …) as a suffix for a normal
"   command, and as a prefix for an object?
"
"   The {lhs} in normal mode can be used as an operator or not.
"   It can be prefixed by an operator or not.
"   2 * 2 possibilities = 4
"
"        Zi is a cmd    o_iw = pb?   NO, because `Ziw` has no meaning; neither Z nor Zi are ops
"        Zi "  an op    o_iw "       NO, because `Ziw` and `Ziiw` both work
"
"        cX "  a cmd    o_Xw "       YES, we can't type `cXw`, the command `cX`
"                                    shadows the operator `c` + the object `Xw`
"
"        cx "  an op    o_xw "       YES, we can't type `c`+`xw` because `cx`  shadows `c`
"                                    and we can't type `cx`+`xw` because `cxx` shadows `cxxw`
"
"                                    The 2 last problems are the consequence of how
"                                    Vim process the typed keys.
"                                    It doesn't invoke an operator until there's no
"                                    ambiguity anymore regarding the operator.
"                                    And as soon as it recognizes an operator without
"                                    ambiguity, it invokes it.
"
" This section is to be reviewed further. In particular, I'm not sure of what
" the rules are regarding the processing of typed keys.
" For example, forget the meaning of the keys, and suppose we have:
"
"    ab   = op
"    cdef = object
"
"    abcd = op
"    ef   = object
"
" When we type `abcdef`, what happens?
"
"     ab   + cdef
" OR
"     abcd + ef
"
" I think Vim gives the priority to the operator, so it will do `abcd` + `ef`.
" But not sure. Make some test.
"
" And if we have:
"
"     ab   = op
"     abc  = op
"     bcde = obj
"     cde  = obj
"     de   = obj
"
" When we type `abcde`, what happens?
"
"     abc + de
" OR
"     ab + cde
"
" All in all, the syntax for operator-pending mode seems very tricky.
" It's probably best to use only `i` and `a` as prefixes in operator-pending
" mode. And maybe even remove `prefix + i/a` (better be safe than sorry).
" Or not. Vim uses `zi` by default, so `prefix + i/a` should be safe to keep.
"
" - In the help, remove the color names, replace them with some text colored
"   with the proper HG; because the names don't match what we've written.
"   For example, the "red" mappings are not red when my colorscheme is dark,
"   they are orange.

"}}}
" The algorithm deliberately omit special keys:"{{{
"
"         <F1> … <F9>
"         <BS>
"         <Del>
"         <Home>
"         <End>
"         <Left>
"         <Right>
"         <Down>
"         <Up>
"         <PageDown>
"         <PageUp>
"         <LeftMouse>
"         <RightMouse>
"         <MiddleMouse>
"         <ScrollWheelDown>
"         <ScrollWheelUp>
"         <ScrollWheelLeft>
"         <ScrollWheelRight>
"         …
"
" If we wanted to add these, to find the syntaxes leading to meaningless
" sequences, we would have to consider 2 cases:
"
"       - the special key is mapped by default to a command:
"
"                 prefix + special key
"                 op     + special key
"
"       - it isn't mapped to anything:
"
"                 special key + anything (including nothing)
"
" We also omit the digits.
" If we wanted to include them, there would be only two possible syntaxes:
"
"                 prefix + digit
"                 digit  + prefix + digit
"
" `g8` and `8g8` are 2 default examples of these syntaxes.
"
" Finally, if we break a default motion/command/operator, it also creates
" new free keys.
" For example, if we use `Space` as the Leader key, then we should consider
" it as a prefix.
" In normal mode, a prefix can be used to produce meaningless sequences, in 2 syntaxes:
"
"         pfx + char    obvious, that's why we chose a Leader key in the first place
"         op  + pfx     NEW
"
" So, now we can use `d Space`, `y Space`, `c Space` …

" "}}}
" candidates "{{{

fu! s:candidates(categories) abort
    let categories = a:categories
    let syntaxes   = s:syntaxes(categories)
    let candidates = []

    for [left_key_category, right_key_category] in values(syntaxes)
        for key1 in left_key_category
            for key2 in right_key_category

                let candidates += [join([key1,key2], '')]

            endfor
        endfor
    endfor

    return candidates
endfu

"}}}
" categories "{{{

fu! s:categories() abort

    let mode     = s:flags.mode
    let noleader = s:flags.noleader

    let categories = {
                     \ 'prefixes'           : ['"', '@', 'm', "'", '`', '[', ']', 'Z', '\', 'g', 'z', '|'],
                     \ 'commands'           : !&tildeop ? ['~'] : [],
                     \ 'operators'          : ['!', '<', '=', '>', 'c', 'd', 'y'] + (&tildeop ? ['~'] : []),
                     \ 'operators_linewise' : ['!', '<', '=', '>'],
                     \ }

    let categories.prefixes +=     (mode ==?    'normal' ? ['U'] : [])
                               \ + (!noleader ? ['Leader']       : [])

    let categories.motions = [
                             \ '*',
                             \ '#',
                             \ '$',
                             \ '%',
                             \ '(',
                             \ ')',
                             \ '+',
                             \ '-',
                             \ ',',
                             \ ';',
                             \ '/',
                             \ '?',
                             \ 'B',
                             \ 'E',
                             \ 'F',
                             \ 'G',
                             \ 'H',
                             \ 'L',
                             \ 'M',
                             \ 'N',
                             \ 'T',
                             \ 'W',
                             \ '^',
                             \ '_',
                             \ 'b',
                             \ 'e',
                             \ 'f',
                             \ 'h',
                             \ 'j',
                             \ 'k',
                             \ 'l',
                             \ 'n',
                             \ 't',
                             \ 'w',
                             \ '{',
                             \ '}',
                             \ ' ',
                             \ 'BS',
                             \ 'CR',
                             \ ]

    " The 18 following motions stay on the line most of the time."{{{
    " The last 11 can move across different lines, but very limitedly.
    " So it doesn't make a lot of sense to use any of them after an operator
    " which acts upon a set of lines.
    " For example:
    "               >h    ✘   works but not intuitive
    "               >>    ✔   better
    "
    "               =b    ✘   the cursor being at the beginning of a line
    "               =k    ✔
    "
    "               !w    ✘   the cursor being at the end of a line
    "               !j    ✔
    "
    " Thus, the syntax:
    "
    "               linewise operator + motion which stays on current line
    "
    " … although valid, is unintuitive and useless.
    "
    " This creates new free key sequences.
    "
    " "}}}

    let categories.motions_stay_on_line = [
                                          \ '$',
                                          \ 'F',
                                          \ 'T',
                                          \ '^',
                                          \ 'f',
                                          \ 't',
                                          \ '|',
                                          \ 'w',
                                          \ 'B',
                                          \ 'E',
                                          \ 'W',
                                          \ 'b',
                                          \ 'e',
                                          \ 'h',
                                          \ 'l',
                                          \ ' ',
                                          \ 'BS',
                                          \ 'CR',
                                          \ ]

    " We don't consider Tab as a motion, because even though `C-I` jumps forward
    " in the jumplist, by default, `operator + Tab` doesn't do anything.
    " So, we could consider it as a command, which gives us the free key sequences:
    "
    "         operator + Tab

    let categories.commands += [
                               \ '&',
                               \ '.',
                               \ ':',
                               \ 'A',
                               \ 'C',
                               \ 'D',
                               \ 'I',
                               \ 'J',
                               \ 'K',
                               \ 'O',
                               \ 'P',
                               \ 'Q',
                               \ 'R',
                               \ 'S',
                               \ 'V',
                               \ 'X',
                               \ 'Y',
                               \ 'a',
                               \ 'i',
                               \ 'o',
                               \ 'p',
                               \ 'q',
                               \ 'r',
                               \ 's',
                               \ 'u',
                               \ 'v',
                               \ 'x',
                               \ 'Tab',
                               \ ]

    " If the `-noleader` argument wasn't provided, it means we want the algo to
    " consider the usage of a Leader key. So, we remove `g:mapleader` from all
    " the categories.
    " Indeed, the key stored in `g:mapleader` should be considered as a prefix,
    " and nothing else.

    if !noleader
        for category in keys(categories)
            call filter(categories[category], 'v:val !=# g:mapleader')
        endfor
    endif

    return categories
endfu

"}}}
" close_window "{{{

fu! s:close_window() abort

    let id_orig_window = b:_fk.id_orig_window
    close
    call win_gotoid(id_orig_window)

endfu

"}}}
" complete "{{{

fu! freekeys#complete(lead, line, _pos) abort

    if a:lead =~ '^-'

        let flags = [
                    \ '-noleader ',
                    \ '-nomapcheck ',
                    \ '-nospecial ',
                    \ '-mode',
                    \ ]

        return filter(flags, 'v:val[:strlen(a:lead)-1] ==# a:lead')

    elseif a:line =~# '-mode \w*$'

        let modes = ['normal', 'visual', 'operator-pending', 'insert', 'command-line']
        return filter(modes, 'empty(a:lead) || v:val[:strlen(a:lead)-1] ==# a:lead')

    endif

    return ''
endfu

"}}}
" display "{{{

fu! s:display(free) abort

    " Get the unique id of the window we're coming from.
    " Necessary to restore the focus correctly when we'll close the FK window.

    let id_orig_window = win_getid()

    tabnew

    let b:_fk = extend(s:flags, {
                                \ 'id_orig_window' : id_orig_window,
                                \ 'leader_key'     : 'shown',
                                \ })

    setl bh=wipe nobl bt=nofile noswf nowrap
    setf freekeys
    if !bufexists('free keys') | sil file free\ keys | endif

    sil 0put =a:free
    sil $d_
    sort

    " Make the space key more visible.

    sil! keepj keepp %s/ /Space/

    " Add spaces around special keys:   BS, CR, CTRL-, Leader, Space, Tab
    " to make them more readable

    sil! keepj keepp %s/^Leader\zs\ze\S/ /
    sil! keepj keepp %s/\v%(CTRL-)@<!%(BS|CR|CTRL-|Leader|Space|Tab)$/ &/
    sil! keepj keepp %s/  / /

    " If there're double sequences, like `operator + space`:
    "
    "         Leader = Space
    "         op_l + motion_s
    "         op   + leader
    "
    " … remove them.

    sil! keepj keepp %s/\v^(.*)\n\1$/\1/

    " Trim whitespace. There shouldn't be any, but better be safe than sorry.

    sil! keepj keepp %s/\s*$//

    call append(0, substitute(s:flags.mode, '.', '\U&', 'g').' MODE')
    1center
    call cursor(1,1)

    nno <silent> <buffer> <nowait> <CR>    :<C-U>call <SID>show_help()<CR>
    nno <silent> <buffer> <nowait> q       :<C-U>call <SID>close_window()<CR>
    nno <silent> <buffer> <nowait> g?      :<C-U>help freekeys-mappings<CR>
    nno <silent> <buffer> <nowait> gc      :<C-U>call <SID>similar_tags()<CR>

    exe 'nno <silent> <buffer> <nowait> gl    :<C-U>call <SID>toggle_leader_key('.s:flags.noleader.')<CR>'

endfu

"}}}
" double_prefixes "{{{

fu! s:double_prefix(prefixes) abort
    let double_prefix = []

    for prefix in a:prefixes
        let double_prefix += [prefix.prefix]
    endfor

    return double_prefix
endfu

"}}}
" is_unmapped "{{{

fu! s:is_unmapped(candidates, default_mappings) abort

    let candidates       = a:candidates
    let default_mappings = a:default_mappings
    let nomapcheck       = s:flags.nomapcheck
    let nospecial        = s:flags.nospecial
    let mode             = s:flags.mode

    " `"`, `@`, `m`, `'`, ```, `[` and `]` are special motions, commands,"{{{
    " because contrary to the other ones, they wait for an argument.
    " This creates a new free key sequence, each time they don't understand an
    " argument.
    " That's why we put them in the prefixes category.
    "
    " This choice of categorization has a consequence: we'll have to REMOVE
    " all the "mapped_to_sth" key sequences generated by our algorithm.
    " If instead we had chosen to categorize them as motions or commands, we
    " would have to do the opposite: ADD the unmapped key sequences forgotten by
    " the algorithm.
    "
    " Why this choice?
    " The "mapped_to_sth" sequences seem to be more structured than the unmapped
    " ones. You can express a large chunk of them with a simple syntax:
    "
    "         prefix + letter
    "
    " So, it's easier to REMOVE MAPPED sequences, than to ADD UNMAPPED sequences.
    "
    " "}}}

    " If a sequence shadows another one, or it overrides a default action,
    " remove it.

    let condition_to_be_free = '!count(default_mappings, key)'

    if nospecial
        let condition_to_be_free .= ' && key !~ "[[:punct:]]"'
    endif

    if !nomapcheck
        let condition_to_be_free .= '&& empty(mapcheck(substitute(key, "Leader", g:mapleader, "g"), "n"))'
    endif

    for key in candidates
        if !eval(condition_to_be_free)
            call remove(candidates, index(candidates, key))
        endif
    endfor

    " Now, we can be sure everything in `candidates` is free.

    return candidates

endfu

"}}}
" main "{{{

fu! freekeys#main(...) abort

    let cmd_args = split(a:1)
    let s:flags  = {
                   \ 'mode'       : matchstr(a:1, '\v-mode\s+\zs%(\w|-)+'),
                   \ 'nospecial'  : count(cmd_args, '-nospecial') ? 1 : 0,
                   \ 'nomapcheck' : count(cmd_args, '-nomapcheck') ? 1 : 0,
                   \ 'noleader'   : count(cmd_args, '-noleader') ? 1 : 0,
                   \ }

    if empty(s:flags.mode)
        let s:flags.mode = 'normal'
    endif

    let categories       = s:categories()
    let candidates       = s:candidates(categories)
    let default_mappings = s:default_mappings(categories)
    let free             = s:is_unmapped(candidates, default_mappings)

    call s:display(free)
endfu

"}}}
" default_mappings "{{{

fu! s:default_mappings(categories) abort

    let mode             = s:flags.mode
    let default_mappings = []
    let prefixes         = a:categories.prefixes
    let operators        = a:categories.operators

    " NOTE:"{{{
    "
    " Why can we copy something in the pseudo-register `~`?     "~yy
    " And why can't we paste it?                                "~p

    " NOTE:
    "
    " What do `@_` and `@~`?
    " They don't raise the error:
    "
    "         E354: Invalid register name:

    " NOTE:
    "
    " We don't remove `m(` and `m(`, because you can't really change them.
    " Vim constantly updates them automatically, so that they
    " match the beginning / end of the current sentence.
    "
    " Same thing for `m{` and `m}`.
    " They match the beginning / end of the current paragraph.
    "
    " Same thing for `m.`, and `m^`.
    " It doesn't seem possible to manually set those marks.
    " They match the last position where resp. a change was made, and
    " insertion mode was stopped.

"}}}

    let default_mappings = {
                           \ 'command-line': {},
                           \ 'insert': {},
                           \ 'operator-pending': {},
                           \ }

    let default_mappings.normal = {
                                  \  'prefix + letter'    : s:prefix_plus_letter(),
                                  \  'double prefix'      : s:double_prefix(prefixes),
                                  \  'op + forbidden cmd' : s:op_plus_forbidden_cmd(operators),
                                  \
                                  \  'mark'               : ['m"', "m'", 'm<', 'm>', 'm[', 'm]', 'm`'],
                                  \  'double operator'    : ['!!', '==', '<<', '>>', 'cc', 'dd', 'yy'],
                                  \  'at'                 : ['@"', '@*', '@+', '@-', '@.', '@/', '@:', '@='],
                                  \
                                  \  'backtick'           : ['`"', '`.', '`(', '`)', '`<', '`>',
                                  \                           '`[', '`]', '`^', '``', '`{', '`}'],
                                  \
                                  \  'double quote'       : ['"+', '"-', '"*', '"/', '"=', '"%', '"#',
                                  \                           '":', '".', '"_'],
                                  \
                                  \  'single quote'       : ['''"', "'.", "'(", "')", "'<", "'>",
                                  \                           "'[", "']", "'^", "'`", "'{", "'}"],
                                  \ }

    let default_mappings.normal.various = [
                                          \ '[*',
                                          \ ']*',
                                          \ '[#',
                                          \ ']#',
                                          \ '[''',
                                          \ ']''',
                                          \ '[(',
                                          \ '])',
                                          \ '[{',
                                          \ ']}',
                                          \ '[]',
                                          \ '][',
                                          \ '[`',
                                          \ ']`',
                                          \ '[/',
                                          \ ']/',
                                          \ '[D',
                                          \ ']D',
                                          \ '[I',
                                          \ ']I',
                                          \ '[M',
                                          \ ']M',
                                          \ '[P',
                                          \ ']P',
                                          \ '[S',
                                          \ ']S',
                                          \ '[c',
                                          \ ']c',
                                          \ '[d',
                                          \ ']d',
                                          \ '[f',
                                          \ ']f',
                                          \ '[i',
                                          \ ']i',
                                          \ '[m',
                                          \ ']m',
                                          \ '[p',
                                          \ ']p',
                                          \ '[s',
                                          \ ']s',
                                          \ '[z',
                                          \ ']z',
                                          \ 'g#',
                                          \ 'g*',
                                          \ 'g$',
                                          \ 'g&',
                                          \ 'g''',
                                          \ 'g+',
                                          \ 'g,',
                                          \ 'g-',
                                          \ 'g;',
                                          \ 'g<',
                                          \ 'g?',
                                          \ 'g@',
                                          \ 'gD',
                                          \ 'gE',
                                          \ 'gF',
                                          \ 'gH',
                                          \ 'gI',
                                          \ 'gJ',
                                          \ 'gN',
                                          \ 'gP',
                                          \ 'gQ',
                                          \ 'gR',
                                          \ 'gT',
                                          \ 'gU',
                                          \ 'g]',
                                          \ 'g^',
                                          \ 'g_',
                                          \ 'g`',
                                          \ 'gd',
                                          \ 'ge',
                                          \ 'gf',
                                          \ 'gh',
                                          \ 'gi',
                                          \ 'gj',
                                          \ 'gk',
                                          \ 'gm',
                                          \ 'gn',
                                          \ 'gp',
                                          \ 'gq',
                                          \ 'gr',
                                          \ 'gs',
                                          \ 'gt',
                                          \ 'gu',
                                          \ 'gv',
                                          \ 'g~',
                                          \ 'ZQ',
                                          \ 'z#',
                                          \ 'z+',
                                          \ 'z-',
                                          \ 'z.',
                                          \ 'z=',
                                          \ 'zCR',
                                          \ 'zA',
                                          \ 'zC',
                                          \ 'zD',
                                          \ 'zE',
                                          \ 'zF',
                                          \ 'zG',
                                          \ 'zH',
                                          \ 'zL',
                                          \ 'zM',
                                          \ 'zN',
                                          \ 'zO',
                                          \ 'zR',
                                          \ 'zW',
                                          \ 'zX',
                                          \ 'z^',
                                          \ 'za',
                                          \ 'zb',
                                          \ 'zc',
                                          \ 'zd',
                                          \ 'ze',
                                          \ 'zf',
                                          \ 'zg',
                                          \ 'zh',
                                          \ 'zi',
                                          \ 'zj',
                                          \ 'zk',
                                          \ 'zl',
                                          \ 'zm',
                                          \ 'zn',
                                          \ 'zo',
                                          \ 'zr',
                                          \ 'zs',
                                          \ 'zt',
                                          \ 'zv',
                                          \ 'zw',
                                          \ 'zx',
                                          \ ]

    let default_mappings.visual = {
                                  \ 'prefix + letter' : s:prefix_plus_letter(),
                                  \ }

    let default_mappings.visual.various = [
                                          \ 'a(',
                                          \ 'a)',
                                          \ 'a<',
                                          \ 'a>',
                                          \ 'aB',
                                          \ 'aW',
                                          \ 'a[',
                                          \ 'a]',
                                          \ 'a`',
                                          \ 'ab',
                                          \ 'ap',
                                          \ 'as',
                                          \ 'at',
                                          \ 'aw',
                                          \ 'a{',
                                          \ 'a}',
                                          \ 'g?',
                                          \ 'gF',
                                          \ 'gN',
                                          \ 'g]',
                                          \ 'gf',
                                          \ 'gn',
                                          \ 'gv',
                                          \ 'i(',
                                          \ 'i)',
                                          \ 'i<',
                                          \ 'i>',
                                          \ 'iB',
                                          \ 'iW',
                                          \ 'i[',
                                          \ 'i]',
                                          \ 'i`',
                                          \ 'ib',
                                          \ 'ip',
                                          \ 'is',
                                          \ 'it',
                                          \ 'iw',
                                          \ 'i{',
                                          \ 'i}',
                                          \ "i'",
                                          \ "a'",
                                          \ ]

    let result = []
    for a_list in values(default_mappings[mode])
        let result += a_list
    endfor

    return result
endfu

"}}}
" op_plus_forbidden_cmd "{{{

fu! s:op_plus_forbidden_cmd(operators) abort

    let op_plus_forbidden_cmd = []

    for operator in a:operators
        for command in ['a', 'i']
            let op_plus_forbidden_cmd += [operator.command]
        endfor
    endfor

    for operator in ['c', 'd', 'y'] + (&tildeop ? ['~'] : [])
        for command in ['v', 'V']
            let op_plus_forbidden_cmd += [operator.command]
        endfor
    endfor

    return op_plus_forbidden_cmd
endfu

"}}}
" prefix_plus_letter "{{{

fu! s:prefix_plus_letter() abort
    let prefix_plus_letter = []

    for prefix in ['"', '@', 'm', "'", '`']
        let prefix_plus_letter += map(range(char2nr('a'),char2nr('z'))+
                                  \   range(char2nr('A'),char2nr('Z')),
                                  \ 'prefix.nr2char(v:val)')
    endfor
    return prefix_plus_letter
endfu

"}}}
" show_help "{{{

fu! s:show_help() abort

    " All tags from the plugin begin with the prefix `fk_` to avoid conflicts
    " with default ones. Add it to the key sequence under the cursor.

    let topic = '\Vfk_'.escape(matchstr(getline('.'), '\S.*\S'), '\')
    let topic = substitute(topic, ' ', '_', 'g')

    let substitutions = {
                        \ 'U'         : ['U\zs.*'             , ''],
                        \ 'Bar'       : ['\zs|.*'             , 'Bar'],
                        \ '[] ctrl-'  : ['[[\]]_CTRL-'        , 'fk_[]_CTRL-'],
                        \ '[] "'      : ['[[\]]"'             , 'fk_[]_double_quote'],
                        \ 'op ctrl-'  : ['\%(c\|d\|y\)_CTRL-' , 'fk_operator_and_CTRL-V'],
                        \ 'op prefix' : ['[!<>=cdy]g'         , 'fk_operator_and_prefix_g'],
                        \ }

    for [pattern, replacement] in values(substitutions)
        let topic = substitute(topic, '^\\Vfk_'.pattern.'$', replacement, '')
    endfor

    if !empty(taglist(topic))
        exe 'help '.topic
    endif
endfu

"}}}
" similar_tags "{{{

fu! s:similar_tags() abort
    let mode     = b:_fk.mode
    let mode_tag = mode !=# 'normal' ? mode[0].'_' : ''
    let lines    = getline(1, line('$'))

    call remove(lines, index(lines, 'g:'))

    vnew
    setl bh=wipe nobl bt=nofile noswf nowrap
    if !bufexists('similar tags') | sil file similar\ tags | endif

    sil 0put =lines
    sil $d_

    for idx in range(line('$'), 1, -1)
        let key      = substitute(getline(idx), ' ', '_', 'g')
        let taglist  = taglist('\C\V\^'. mode_tag .escape(key, '\'))
        let tagnames = map(taglist, '"    ".escape(v:val["name"], "/")')

        if empty(tagnames)
            sil exe idx.'d_'
        else
            sil exe 'keepj keepp '.idx.'s/$/\=[""]+tagnames'
        endif
    endfor

    nno <silent> <buffer> <nowait> q    :<C-U>close<CR>
endfu

"}}}
" syntaxes "{{{

fu! s:syntaxes(categories) abort

    let mode       = s:flags.mode
    let categories = a:categories

    let prefixes             = categories.prefixes
    let motions              = categories.motions
    let motions_stay_on_line = categories.motions_stay_on_line
    let commands             = categories.commands
    let operators            = categories.operators
    let operators_linewise   = categories.operators_linewise

    let chars                = prefixes+motions+commands+operators

    let syntaxes = {
                   \ 'insert'          : {
                   \                       'ctrl + char' : [['CTRL-'], chars],
                   \                       },
                   \ 'command-line'    : {
                   \                       'ctrl + char' : [['CTRL-'], chars],
                   \                       },
                   \ 'operator-pending': {
                   \                       'adverb + char' : [['i', 'a'], chars],
                   \                       },
                   \ }

    " In visual mode, we don't put `i`, `a` inside the commands category
    " because of the convention which uses them as prefix to build
    " text-objects.

    let syntaxes.visual = {
                          \ 'pfx + char'  : [prefixes               , chars],
                          \ 'pfx + CTRL'  : [prefixes               , ['CTRL-']],
                          \ 'CTRL + char' : [['CTRL-']              , chars],
                          \ 'cmd + char'  : [['&', '.', 'Q', 'Tab'] , chars],
                          \ }

    " Most of the meaningless sequences need at least 2 keys.
    " But one of them need at least 3 keys:    digit + prefix + digit

    let syntaxes.normal = {
                          \ 'pfx  + char'     : [prefixes,            chars],
                          \ 'op   + cmd'      : [operators,           commands],
                          \ 'op1  + op2'      : [operators,           operators],
                          \ 'op   + pfx'      : [operators,           prefixes],
                          \ 'op_l + motion_s' : [operators_linewise,  motions_stay_on_line],
                          \ 'CTRL + char'     : [['CTRL-'],           ['K', 'Space', '\', '_', '@']],
                          \ 'op   + CTRL'     : [operators,           ['CTRL-']],
                          \ 'pfx  + CTRL'     : [prefixes,            ['CTRL-']],
                          \ }

    " These 8 syntaxes should produce all 2-key meaningless sequences.
    " For n-key meaningless sequences (n>2), there's only 1 possible syntax:
    "
    "         - meaningless + anything

    " CTRL is treated as a special prefix.
    " Indeed, there are very few USABLE unmapped key sequences with `CTRL-`.
    "
    " Beginning with `CTRL-`, I only found 4:
    "
    "                     CTRL-K
    "                     CTRL-\
    "                     CTRL-_
    "                     CTRL-Space or CTRL-@
    "
    " Ending with `CTRL-`, I only found 2:
    "
    "                     op     + CTRL-
    "                     prefix + CTRL-    with some exceptions like g C-G

    return syntaxes[mode]
endfu

"}}}
" toggle_leader_key "{{{

fu! s:toggle_leader_key(noleader) abort

    if a:noleader
        return ''
    endif

    let cur_pos = getcurpos()

    if b:_fk.leader_key ==# 'shown'
        sil! exe 'keepj keepp %s/Leader/'.substitute(g:mapleader, ' ', 'Space', '').'/g'
    else
        sil! exe 'keepj keepp %s/'.substitute(g:mapleader, ' ', 'Space', '').'/Leader/g'
    endif

    call setpos('.', cur_pos)

    let b:_fk.leader_key = filter(['shown', 'replaced'], 'v:val !=# b:_fk.leader_key')[0]
endfu

"}}}