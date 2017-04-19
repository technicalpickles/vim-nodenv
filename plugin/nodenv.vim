" nodenv.vim - nodenv support
" Maintainer:   Tim Pope <http://tpo.pe/>
" Version:      1.1

if exists("g:loaded_nodenv") || v:version < 700 || &cp || !executable('nodenv')
  finish
endif
let g:loaded_nodenv = 1

command! -bar -nargs=* -complete=custom,s:Complete Nodenv
      \ if get([<f-args>], 0, '') ==# 'shell' |
      \   exe s:shell(<f-args>) |
      \ else |
      \   exe '!nodenv ' . <q-args> |
      \   call extend(g:node_version_paths, s:node_version_paths(), 'keep') |
      \ endif

function! s:shell(_, ...)
  if !a:0
    if empty($NODENV_VERSION)
      echo 'nodenv.vim: no shell-specific version configured'
    else
      echo $NODENV_VERSION
    endif
    return ''
  elseif a:1 ==# '--unset'
    let $NODENV_VERSION = ''
  elseif !isdirectory(s:nodenv_root() . '/versions/' . a:1)
    echo 'nodenv.vim: version `' . a:1 . "' not installed"
  else
    let $NODENV_VERSION = a:1
  endif
  call s:set_paths()
  if &filetype ==# 'javascript'
    set filetype=javascript
  endif
  return ''
endfunction

function! s:Complete(A, L, P)
  if a:L =~# ' .* '
    return system("nodenv completions".matchstr(a:L, ' .* '))
  else
    return system("nodenv commands")
  endif
endfunction

function! s:nodenv_root()
  return empty($NODENV_ROOT) ? expand('~/.nodenv') : $NODENV_ROOT
endfunction

function! s:node_version_paths() abort
  let dict = {}
  let root = s:nodenv_root() . '/versions/'
  for entry in split(glob(root.'*'))
    let ver = entry[strlen(root) : -1]
    let paths = ver =~# '^1.[0-8]' ? ['.'] : []
    "let paths += split($RUBYLIB, ':')
    "let site_ruby_arch = glob(entry . '/lib/ruby/site_ruby/*.*/*-*')
    "if empty(site_ruby_arch) || site_ruby_arch =~# "\n"
    "  continue
    "endif
    "let arch = fnamemodify(site_ruby_arch, ':t')
    "let minor = fnamemodify(site_ruby_arch, ':h:t')
    "let paths += [
    "      \ entry . '/lib/ruby/site_ruby/' . minor,
    "      \ entry . '/lib/ruby/site_ruby/' . minor . '/' . arch,
    "      \ entry . '/lib/ruby/site_ruby',
    "      \ entry . '/lib/ruby/vendor_ruby/' . minor,
    "      \ entry . '/lib/ruby/vendor_ruby/' . minor . '/' . arch,
    "      \ entry . '/lib/ruby/vendor_ruby',
    "      \ entry . '/lib/ruby/' . minor,
    "      \ entry . '/lib/ruby/' . minor . '/' . arch]
    let dict[ver] = paths
  endfor
  return dict
endfunction

if !exists('g:node_version_paths')
  let g:node_version_paths = {}
endif

function! s:set_paths() abort
  call extend(g:node_version_paths, s:node_version_paths(), 'keep')
  if !empty($NODENV_VERSION)
    let ver = $NODENV_VERSION
  elseif filereadable(s:nodenv_root() . '/version')
    let ver = get(readfile(s:nodenv_root() . '/version', '', 1), 0, '')
  else
    return
  endif
  if has_key(g:node_version_paths, ver)
    let g:node_default_path = g:node_version_paths[ver]
  else
    unlet! g:node_default_path
  endif
endfunction

call s:set_paths()

function! s:projectionist_detect() abort
  let root = s:nodenv_root() . '/plugins/'
  let file = get(g:, 'projectionist_file', get(b:, 'projectionist_file', ''))
  if file[0 : len(root)-1] ==# root
    call projectionist#append(root . matchstr(file, '[^/]\+', len(root)), {
          \ "bin/nodenv-*": {"command": "command", "template": [
          \   '#!/usr/bin/env bash',
          \   '#',
          \   '# Summary:',
          \   '#',
          \   '# Usage: nodenv {}',
          \ ]},
          \ "etc/nodenv.d/*.bash": {"command": "hook"}})
  endif
endfunction

augroup nodenv
  autocmd!
  autocmd User ProjectionistDetect call s:projectionist_detect()
augroup END

" vim:set et sw=2:
