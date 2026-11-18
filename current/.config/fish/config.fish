source /usr/share/cachyos-fish-config/cachyos-config.fish

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/ben/.lmstudio/bin
# End of LM Studio CLI section

if status is-interactive
    function fish_greeting
    end

    set -g fish_color_normal dce2e4
    set -g fish_color_command e6eeec
    set -g fish_color_param b8c4cb
    set -g fish_color_option 9ab8df
    set -g fish_color_quote d8b582
    set -g fish_color_autosuggestion 829099
    set -g fish_color_comment 74818a
    set -g fish_color_error ff8c90
    set -g fish_color_operator ed7379
    set -g fish_color_redirection 86bec8
    set -g fish_color_end 9ab8df

    # Keep Pure's Git, status and timing details in the terminal palette.
    set -g pure_color_current_directory a1d9c6
    set -g pure_color_prompt_on_success a1d9c6
    set -g pure_color_prompt_on_error ff8c90
    set -g pure_color_git_branch a9b9d0
    set -g pure_color_git_dirty d8b582
    set -g pure_show_exit_status true
end
