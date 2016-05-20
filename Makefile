deps:
	@if [ `uname` = "Darwin" ]; then \
	  if ! which brew; then \
	    echo "Installing Brew"; \
	    ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; \
	  fi; \
	  if ! which VirtualBox; then \
	    echo "Installing VirtualBox"; \
	    brew cask install virtualbox; \
	  fi; \
	  if ! which Vagrant; then \
	    echo "Installing Vagrant"; \
	    brew cask install vagrant; \
	  fi; \
	  if ! vagrant plugin list | grep vagrant-cachier; then \
	    echo "Installing vagrant-cachier"; \
	    vagrant plugin install vagrant-cachier; \
	  fi; \
	  if ! vagrant plugin list | grep vagrant-vbguest; then \
	    echo "Installing vagrant-vbguest"; \
	    vagrant plugin install vagrant-vbguest; \
	  fi; \
	fi

encrypt:
	secure encrypt

decrypt:
	secure decrypt

clean:
	find . -type f -name '*.private' |xargs rm -rf

git-add-encrypted:
	find . -type f -name '*.encrypted.*' | xargs -n 1 git add
