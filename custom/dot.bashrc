## Custom: Everything below this line is auto-edited by vagrant setup.sh scripts

# for golang
export GOPATH=/home/vagrant/go
export PATH=$PATH:./bin:/usr/local/go/bin

# for terraform
export PATH=$PATH:/usr/local/terraform/bin

# Install direnv (used to setup golang GOPATH if a .envrc file is found)
eval "$(direnv hook bash)"

# for gcloud, kubectl
export PATH=$PATH:/usr/local/google-cloud-sdk/bin


#####################################################################
# Enable re-attaching screen sessions with ssh-agent support
if [[ -n "$SSH_TTY" && -S "$SSH_AUTH_SOCK" && ! -L "$SSH_AUTH_SOCK" ]]; then
    rm -f ~/.ssh/ssh_auth_sock
    ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock
    export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
fi
#####################################################################