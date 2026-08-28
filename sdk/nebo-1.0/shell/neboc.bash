_neboc_complete() { COMPREPLY=( $(compgen -W "check emit-asm build --help --version" -- "${COMP_WORDS[COMP_CWORD]}") ); }
complete -F _neboc_complete neboc
