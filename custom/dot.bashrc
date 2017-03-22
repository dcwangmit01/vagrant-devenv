## Custom: Everything below this line is auto-edited by vagrant setup.sh scripts

silent() {
    "$@" 2>&1 > /dev/null
}

# emacs
export EDITOR=emacs

# for golang
export GOPATH=/go
export PATH=./bin:./vendor/bin:$GOPATH/bin:/usr/local/go/bin:$PATH

# for protocol buffers
export PATH=$PATH:/usr/local/protoc/bin

# for terraform
export PATH=$PATH:/usr/local/terraform/bin

# for gcloud, kubectl
export PATH=$PATH:/usr/local/google-cloud-sdk/bin

# Install direnv (used to setup golang GOPATH if a .envrc file is found)
if silent which direnv; then
   eval "$(direnv hook bash)"
fi

# enable hub alias to git if hub is installed
if silent which hub; then
   eval "$(hub alias -s)"
fi

#####################################################################
# Enable re-attaching screen sessions with ssh-agent support
#   Only for interactive sessions
if tty -s; then
    if [[ -n "${SSH_TTY:-''}" && -S "$SSH_AUTH_SOCK" && ! -L "$SSH_AUTH_SOCK" ]]; then
        rm -f ~/.ssh/ssh_auth_sock
        ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock
        export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
    fi
fi
#####################################################################