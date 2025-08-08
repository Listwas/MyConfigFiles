#
# ~/.zshrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias ll='ls -la'
alias grep='grep --color=auto'

PS1="%B%F{#7c05d5}%n%f%b %~ "

#custom aliases
alias r='source ~/.zshrc; echo zsh reloaded' 
alias config='cd $HOME/.config/; ls'
alias ba='vim ~/.zshrc'
alias wifi='nmcli dev wifi rescan; nmtui'
alias bright='sudo vim /sys/class/backlight/amdgpu_bl1/brightness'
alias bat='sudo vim /sys/class/power_supply/BAT0/charge_control_end_threshold'
alias spwm='vim $HOME/.config/bspwm/bspwmrc'
alias gs='git status'
alias gl='git log --oneline'
alias monitor='conky'

libre() {
    libreoffice "$1" & disown
}

# clear aliases
alias clea4r='clear'
alias clar='clear'
alias claer='clear'
alias clae='clear'
alias cls='clear'

# Autocomplete settings
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion::complete:*' use-cache on
zstyle ':completion:*:*:*:*:processes' command'ps -u $USER -o pid,user,comm,cmd -w -w'

# Keep history alive between resets
setopt inc_append_history
setopt complete_aliases
setopt complete_in_word
setopt auto_list
setopt append_history

autoload -Uz compinit
bindkey "^[[3~" delete-char

update-mirrorlist() {
	curl "https://archlinux.org/mirrorlist/?country=PL&protocol=https&ip_version=4&use_mirror_status=on" | sed 's/^#//g' > /tmp/mirrorlist.new
	sudo mv /tmp/mirrorlist.new /etc/pacman.d/mirrorlist
}


export GOROOT=$HOME/.local/opt/go-v1.24.3
export PATH=$GOROOT/bin:$PATH
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
