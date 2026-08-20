# ~/.zprofile — login shells only. Runs AFTER /etc/zprofile (path_helper),
# which reorders PATH to put system dirs first, demoting everything ~/.zshenv
# set up. Re-assert the .zshenv ordering; entries path_helper added that we
# don't know about stay, appended after ours (typeset -U dedupes, first wins).
if [[ -n "$_ZENV_PATH" ]]; then
    path=( ${(s.:.)_ZENV_PATH} $path )
    unset _ZENV_PATH
fi

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
