

encrypt:
	./bin/secure.sh encrypt

decrypt:
	./bin/secure.sh decrypt

clean:
	find . -type f -name '*.private' |xargs rm -rf

git-add-encrypted:
	find . -type f -name '*.encrypted.*' | xargs -n 1 git add
