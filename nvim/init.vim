call plug#begin('~/.vim/plugged')

Plug 'tanvirtin/monokai.nvim'
Plug 'ms-jpq/chadtree', {'branch': 'chad', 'do': 'python3 -m chadtree deps'}
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'ap/vim-buftabline'
Plug 'rbgrouleff/bclose.vim'
Plug 'scrooloose/nerdcommenter'
Plug 'mattn/emmet-vim'
Plug 'yuezk/vim-js'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
Plug 'editorconfig/editorconfig-vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'kevinoid/vim-jsonc'
Plug 'tpope/vim-fugitive'
Plug 'jparise/vim-graphql'
Plug 'jxnblk/vim-mdx-js'

call plug#end()

let g:coc_global_extensions = ['coc-tsserver', 'coc-prettier', 'coc-eslint']
let g:coc_node_path = '/home/andrew/.nvm/versions/node/v14.19.1/bin/node'

set nocompatible              " be iMproved, required
filetype off                  " required

set wildignore+=*.pyc,*.o,*.swp,*.DS_Store

let NERDTreeRespectWildIgnore=1

let g:chadtree_settings = { 'theme.text_colour_set': 'solarized_dark', 'keymap.change_focus': ['B'] }


map <C-n> :CHADopen<CR>


syntax on
filetype plugin indent on

set mouse=a

" TODO: Pick a leader key
let mapleader = " "

" Security
set modelines=0
set number " Show line numbers
set ruler " Show file stats
set visualbell " Blink cursor on error instead of beeping (grr)
set encoding=utf-8

" Whitespace
set wrap
set textwidth=79
set formatoptions=tcqrn1
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set noshiftround

" Cursor motion
set scrolloff=3
set backspace=indent,eol,start
set matchpairs+=<:> " use % to jump between pairs

" Move up/down editor lines
nnoremap j gj
nnoremap k gk

set hidden " Allow hidden buffers

set ttyfast " Rendering
set updatetime=300

set laststatus=2 " Status bar

" Last line
set showmode
set showcmd

nnoremap ; :

" Searching
nnoremap / /\v
vnoremap / /\v
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch
map <leader><space> :let @/=''<cr> " clear search

" Visualize tabs and newlines
set listchars=tab:▸\ ,eol:¬
" Uncomment this to enable by default:
" set list " To enable by default
" Or use your leader key + l to toggle on/off
map <leader>k :set list!<CR> " Toggle tabs and EOL

set t_Co=256

colorscheme monokai_pro
hi Normal guibg=NONE ctermbg=NONE

nnoremap <leader>v :vsp<CR>
nnoremap <leader>s :sp<CR>

" Easier split navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" More natural split opening
set splitbelow
set splitright


" Vim buffers and buffer navigation
set hidden
nnoremap <leader>l :bnext<CR>
nnoremap <leader>h :bprev<CR>

let g:bclose_no_plugin_map="true"
nnoremap <silent> <leader>q :bd<CR>

" macOS copy
vnoremap <M-c> "+y
" Linux copy
vnoremap <C-c> "+y

command! -nargs=0 Prettier :CocCommand prettier.formatFile

call system('mkdir ' . '~/.vim/undodir')
set undodir=~/.vim/undodir
set undofile

set nofixendofline

hi! CocErrorSign guifg=#d1666a
hi! CocInfoSign guibg=#353b45
hi! CocWarningSign guifg=#d1cd66

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)


" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Press F12 to fix syntax highlighting when vim screws it up
noremap <F12> <Esc>:syntax sync fromstart<CR>
inoremap <F12> <C-o>:syntax sync fromstart<CR>


nnoremap <silent> <ESC><ESC> :nohlsearch \| match none \| 2match none \| call coc#float#close_all()<CR>

" Gets the root of the Git repo or submodule, relative to the current buffer
function! GetGitRoot()
  return systemlist('git -C ' . shellescape(expand('%:p:h')) . ' rev-parse --show-toplevel')[0]
endfunction

" AgIn: Start ag in the specified directory
"
" e.g.
"   :AgIn .. foo
function! s:ag_in(bang, ...)
  let start_dir=expand(a:1)

  if !isdirectory(start_dir)
    throw 'not a valid directory: ' .. start_dir
  endif
  " Press `?' to enable preview window.
  call fzf#vim#ag(join(a:000[1:], ' '), fzf#vim#with_preview({'dir': start_dir}, 'up:50%:hidden', '?'), a:bang)

endfunction

command! -bang -nargs=+ -complete=dir AgIn call s:ag_in(<bang>0, <f-args>)

" Search by file name
nmap <C-p> :GFiles<cr>
" Search by file content
nmap <C-s> :AgIn  `=GetGitRoot()`<cr>
