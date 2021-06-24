"# General
set title           " Set title of terminal to file name
set noerrorbells    " No beep for most error
set visualbell      " No beep but flash
set t_vb=
syntax on
set nowrap          " Don't wrap lines
"set linebreak      " Break lines at word (requires Wrap lines)
"set showbreak=+++  " Wrap-broken line prefix
"set textwidth=100  " Line wrap (number of cols)
set expandtab       " Replace Tab by Spaces
set tabstop=4       " Tab = 4 Spaces
set autoindent      " Always auto indent
set copyindent      " Copy intentation for auto indent
set smartindent     " Enable smart-indent
set shiftwidth=4    " Number of Spaces for auto indent
"set smarttab       " Insert Tab at start or line according to shiftwidth
set number          " Show line numbers
"set relativelinenumber     " Relative Line Number
set cursorline      " Show cursor line
set showmatch       " Show matching parathesis
set ignorecase      " Ignore case when searching
set smartcase       " Ignore case for lower case only search
set hlsearch        " Highlight search terms
set incsearch       " Show matches as you type

"# Advanced
set ruler               " Show row and column ruler information
set undolevels=1000     " Number of undo levels
set backspace=indent,eol,start      " Allow backspacing over everything in insert mode
