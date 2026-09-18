# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
    git
    fzf
    fzf-tab
    fast-syntax-highlighting
    zsh-autosuggestions
    zsh-bat
    command-not-found
    extract
    sudo
    web-search
)

source $ZSH/oh-my-zsh.sh

# User configuration

export OPENOCD_SCRIPTS_PATH="C:/Users/$WIN_USER/openocd/openocd/scripts"
export PATH="$PATH:$HOME/.local/bin"
export CMAKE_GENERATOR="Ninja"

# --- WSL <-> Windows interop -------------------------------------------------
alias cube="/mnt/c/Users/$WIN_USER/AppData/Local/Programs/STM32CubeMX/STM32CubeMX.exe"
alias cmonitor="/mnt/c/Users/$WIN_USER/AppData/Local/STM32CubeMonitor/STM32CubeMonitor.exe"
alias open="cmd.exe /C start"
alias cp_path="pwd | clip.exe"

# --- general aliases ---------------------------------------------------------
alias add="sudo nala install -y"
alias update="sudo nala upgrade -y; sudo nala autoremove; sudo nala clean"
alias ls="eza --icons --color=always"
alias configure="cmake -B build"
alias build="cmake --build build"
alias fzfp='fzf --preview "batcat --color=always {}" --preview-window "~3"'
alias cd..="cd .."

function clear_local() {
    git fetch --prune
    git branch --delete $(git for-each-ref --format '%(if:equals=gone)%(upstream:track,nobracket)%(then)%(refname:short)%(end)' refs/heads/)
}

function take() {
    mkdir -p "$1"
    cd "$1"
}

# Abre o repositório remoto na branch atual no navegador
function open_remote() {
    origin_url=$(git remote get-url origin)
    repo_url=$(echo "$origin_url" | grep -o 'github\.com[:/].*\.git' | sed 's/github\.com[:/]\(.*\)\.git/\1/')
    branch_name=$(git symbolic-ref --short HEAD)

    if [ -n "$repo_url" ] && [ -n "$branch_name" ]; then
        url="https://github.com/$repo_url/tree/$branch_name"
        echo "Abrindo repositório remoto na branch atual no navegador: $url"
        open "$url"
    else
        echo "Não foi possível determinar o link remoto ou a branch atual."
    fi
}

function reclone() {
    repo_url=$(git remote get-url origin)
    branch_name=$(git symbolic-ref --short HEAD)
    repo_directory=$(pwd)

    if [ -n "$repo_url" ] && [ -n "$branch_name" ]; then
        echo $repo_url
        cd ..
        rm -rf $repo_directory
        git clone $repo_url
        cd $repo_directory
        git checkout $branch_name
        git pull
    else
        echo "Não foi possível determinar o link remoto ou a branch atual."
    fi
}

eval "$(mise activate zsh)"
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
