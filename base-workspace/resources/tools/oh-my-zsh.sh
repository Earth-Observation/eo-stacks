#!/bin/sh

# Stops script execution if a command has an error
set -e

INSTALL_ONLY=0
# Loop through arguments and process them: https://pretzelhands.com/posts/command-line-flags
for arg in "$@"; do
    case $arg in
        -i|--install) INSTALL_ONLY=1 ; shift ;;
        *) break ;;
    esac
done

if ! -d $HOME/.oh-my-zsh ; then
    echo "Installing Oh My ZSH. Please wait..."
    apt-get update
    apt-get install --yes zsh
    # Install powerline font - required for lots of themes
    # Does not work on ubunutu 18.04: apt-get install -y --no-install-recommends fonts-powerline
    # https://github.com/powerline/fonts/issues/281#issuecomment-417473240
    # Install plugins
    apt-get install -y --no-install-recommends autojump git-flow git-extras ncdu htop
    # pip install Pygments ranger-fm thefuck bpytop
    # Install fkill-cli: (too big - 30MB) npm install --global fkill-cli && \
    # yes | sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    # Install powerlevel10k for instant prompt
    # git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    # https://www.reddit.com/r/zsh/comments/dht4zt/make_zsh_start_instantly_with_this_one_weird_trick/
    # Install plugins
    # git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    # git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    # git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
    # git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
    # git clone https://github.com/supercrabtree/k ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/k
    # git clone https://github.com/chrissicool/zsh-256color ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-256color
    # curl -fsSL -o $RESOURCES_PATH/instant-zsh.zsh https://gist.github.com/romkatv/8b318a610dc302bdbe1487bb1847ad99/raw

    git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
    git clone https://github.com/supercrabtree/k ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/k
    git clone https://github.com/chrissicool/zsh-256color ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-256color
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/themes/powerlevel10k


    mkdir -p ~/.fonts
    cd ~/.fonts
    # FiraCode
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Bold/complete/Fira%20Code%20Bold%20Nerd%20Font%20Complete.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Light/complete/Fira%20Code%20Light%20Nerd%20Font%20Complete.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Medium/complete/Fira%20Code%20Medium%20Nerd%20Font%20Complete.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Regular/complete/Fira%20Code%20Regular%20Nerd%20Font%20Complete.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Retina/complete/Fira%20Code%20Retina%20Nerd%20Font%20Complete.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/SemiBold/complete/Fira%20Code%20SemiBold%20Nerd%20Font%20Complete.ttf
    # SourceCodePro
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/SourceCodePro/Regular/complete/Sauce%20Code%20Pro%20Nerd%20Font%20Complete.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/SourceCodePro/Bold/complete/Sauce%20Code%20Pro%20Bold%20Nerd%20Font%20Complete.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/SourceCodePro/Italic/complete/Sauce%20Code%20Pro%20Italic%20Nerd%20Font%20Complete.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/SourceCodePro/Bold-Italic/complete/Sauce%20Code%20Pro%20Bold%20Italic%20Nerd%20Font%20Complete.ttf
    # MesloLGS
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/S/Regular/complete/Meslo%20LG%20S%20Regular%20Nerd%20Font%20Complete.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/S/Bold/complete/Meslo%20LG%20S%20Bold%20Nerd%20Font%20Complete.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/S/Italic/complete/Meslo%20LG%20S%20Italic%20Nerd%20Font%20Complete.ttf
    wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/S/Bold-Italic/complete/Meslo%20LG%20S%20Bold%20Italic%20Nerd%20Font%20Complete.ttf


    # Use avit theme instead of typewritten: Install typewritten theme
    # git clone https://github.com/reobin/typewritten.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/typewritten
    # ln -s "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/typewritten/typewritten.zsh-theme" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/typewritten.zsh-theme"
    # ln -s "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/typewritten/async.zsh" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/async"
    # \nexport TYPEWRITTEN_PROMPT_LAYOUT=\"pure\"\nexport TYPEWRITTEN_COLOR_MAPPINGS=\"primary:cyan\"
    # Other good themes: avit, clean

    # Fix red arrow problem with avit theme
    sed -i 's/fg\[red\]}.${fg\[white\]})%}▶/fg\[white\]}.${fg\[white\]})%}▶/g' ~/.oh-my-zsh/themes/avit.zsh-theme


tee ~/.zshrc << END
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]]; then
  source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"
fi

export source ZSH="/home/jovyan/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
ZSH_THEME="candy"

DISABLE_AUTO_UPDATE="true"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=245"
plugins=(git k extract cp pip yarn npm sudo zsh-256color supervisor rsync command-not-found autojump colored-man-pages git-flow git-extras httpie python zsh-autosuggestions history-substring-search zsh-completions zsh-syntax-highlighting)
source \$ZSH/oh-my-zsh.sh
LS_COLORS=""
export LS_COLORS
alias pcat="pygmentize -g"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

END
    # printf "export source ZSH=\"$HOME/.oh-my-zsh\"\nZSH_THEME=\"avit\"\nDISABLE_AUTO_UPDATE=\"true\"\nZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=\"fg=245\"\nplugins=(git k extract cp pip yarn npm sudo zsh-256color supervisor rsync command-not-found autojump colored-man-pages git-flow git-extras httpie python zsh-autosuggestions history-substring-search zsh-completions zsh-syntax-highlighting)\nsource \$ZSH/oh-my-zsh.sh\nLS_COLORS=\"\"\nexport LS_COLORS\nalias pcat=\"pygmentize -g\"\neval \"\$(pyenv init -)\"\neval \"\$(pyenv virtualenv-init -)\"" > ~/.zshrc

    # # Also add fzf to plugins
    # git clone --depth 1 https://github.com/junegunn/fzf.git $RESOURCES_PATH/.fzf
    # y | $RESOURCES_PATH/.fzf/install

    # TODO install zsh completions?
    # sudo sh -c "echo 'deb http://download.opensuse.org/repositories/shells:/zsh-users:/zsh-completions/xUbuntu_16.04/ /' > /etc/apt/sources.list.d/shells:zsh-users:zsh-completions.list"
    # wget -nv https://download.opensuse.org/repositories/shells:zsh-users:zsh-completions/xUbuntu_16.04/Release.key -O Release.key
    # sudo apt-key add - < Release.key
    # sudo apt-get update
    # sudo apt-get install zsh-completions
	chmod 755 -R ~/.oh-my-zsh

else
    echo "ZSH is already installed"
fi


# docker, kubectl
# Run
if [ $INSTALL_ONLY = 0 ] ; then
    echo "Sourcing ZSH"
    zsh
fi
