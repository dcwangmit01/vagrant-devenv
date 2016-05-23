## Custom: Everything below this line is auto-edited by vagrant setup.sh scripts

# for golang
export PATH=$PATH:./bin:/usr/local/go/bin

# for terraform
export PATH=$PATH:/usr/local/terraform/bin

# Install direnv (used to setup golang GOPATH if a .envrc file is found)
eval "$(direnv hook bash)"

# for gcloud, kubectl
export PATH=$PATH:~/google-cloud-sdk/bin
