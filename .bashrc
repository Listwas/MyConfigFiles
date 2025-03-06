#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias ll='ls -la'
alias grep='grep --color=auto'

PS1='[\u@\h \W]\$ '

#custom aliases
alias r='source ~/.bashrc; echo bash reloaded' 
alias config='cd $HOME/.config/; ls'
alias bash='vim ~/.bashrc'
alias wifi='nmtui'
alias bright='sudo vim /sys/class/backlight/amdgpu_bl1/brightness'
alias bat='sudo vim /sys/class/power_supply/BAT0/charge_control_end_threshold'
alias bspwm='vim $HOME/.config/bspwm/bspwmrc'
update-mirrorlist() {
	curl "https://archlinux.org/mirrorlist/?country=PL&protocol=https&ip_version=4&use_mirror_status=on" | sed 's/^#//g' > /tmp/mirrorlist.new
	sudo mv /tmp/mirrorlist.new /etc/pacman.d/mirrorlist
}

alias gs='git status'
alias gl='git log --oneline'
alias monitor='conky'
