USAGE=$(cat << 'EOF'
Usage: secure.sh encrypt
       secure.sh decrypt
       secure.sh genkeys
       secure.sh loadkeys
       secure.sh deps
       secure.sh usage

Arguments:
  none
Options:
  -h --help  help

GPG can be used to do multi-party encryption/decryption.  For example,
you can encrypt a file which several parties may decrypt using their
own private keys.  Here's how to do it using this wrapper tool.

* Before you start, ensure you have gpg installed
  - On Centos6: yum -y install gpg
  - On Ubuntu: apt-get -y install gpg
  - On OSX: brew install gpg
* First, generate your own gpg keys
  - secure.sh genkeys
* Then, load other people's public keys, which you will use to encrypt.
  - secure.sh loadkeys
* Name any directory or file that you wish to encrypt with the
  ".private" extension suffix.
* Make sure to add "*.private" to .gitignore
* Check in the file, as well as your new public key
  - git add ./secure/gpgkeys/you@domain.com.gpg
  - git add ./secure/encrypted/you.enc
* Now, anyone who had previously added their public gpg in
  ./secure/gpgkeys should be able to decrypt the new file, using their
  own public key, using the command:
  - secure.sh decrypt
EOF
)

#######################################
PARENT_DIR=`pwd`
KEY_DIR=$PARENT_DIR/.gpgkeys
BACKUP_DIR=~/.gnupg/backup


COMMAND=""
if [ "$#" -eq 0 ]; then
    COMMAND="usage"
else
    COMMAND=$1
fi


# Create the gpg recipients list
pushd $KEY_DIR > /dev/null
RECIPIENTS=""
for user in $(find . -maxdepth 1 -mindepth 1 -type f -name '*.gpg' \
    | sed 's@.gpg@@g; s@^./@@g;' )
do
    RECIPIENTS+="--recipient $user "
done
popd > /dev/null


case "$COMMAND" in

    encrypt)

        # First, multi-party encrypt files (in case private files live within private dirs)
	for file in $(find . -type f -name '*.private' \
	    | sed 's@.private@@g; s@^./@@g;' )
	do
	    PRIVATE_FILE="${file}.private"
	    ENCRYPTED_FILE="${file}.encrypted.file"
	    echo "Encrypting"
	    echo "  $PRIVATE_FILE"
	    echo "    as"
	    echo "  $ENCRYPTED_FILE"
	    tar cjv $PRIVATE_FILE | gpg -q --batch --yes --trust-model always --output $ENCRYPTED_FILE --encrypt $RECIPIENTS
	done

	# Next, multi-party encrypt directories
	for dir in $(find . -type d -name '*.private' \
	    | sed 's@.private@@g; s@^./@@g;' )
	do
	    PRIVATE_DIR="${dir}.private"
	    ENCRYPTED_DIR="${dir}.encrypted.dir"
	    echo "Encrypting"
	    echo "  $PRIVATE_DIR"
	    echo "    as"
	    echo "  $ENCRYPTED_DIR"
	    tar cjv $PRIVATE_DIR | gpg -q --batch --yes --trust-model always --output $ENCRYPTED_DIR --encrypt $RECIPIENTS
	done
	;;

    decrypt)

	read -p "Enter the password for your GPG key: " -s PASSWORD
	echo

	# First, multi-party decrypt directories
	for dir in $(find . -type f -name '*.encrypted.dir' \
	    | sed 's@.encrypted.dir@@g; s@^./@@g;' )
	do
	    PRIVATE_DIR="${dir}.private"
	    ENCRYPTED_DIR="${dir}.encrypted.dir"
	    echo "Decrypting"
	    echo "  $ENCRYPTED_DIR"
	    echo "    as"
	    echo "  $PRIVATE_DIR"
	    echo "$PASSWORD" | gpg -q --batch --yes --passphrase-fd 0 --decrypt $ENCRYPTED_DIR | tar xjv -C .
	done

        # Next, multi-party decrypt files
	for file in $(find . -type f -name '*.encrypted.file' \
	    | sed 's@.encrypted.file@@g; s@^./@@g;' )
	do
	    PRIVATE_FILE="${file}.private"
	    ENCRYPTED_FILE="${file}.encrypted.file"
	    echo "Decrypting"
	    echo "  $ENCRYPTED_FILE"
	    echo "    as"
	    echo "  $PRIVATE_FILE"
	    echo "$PASSWORD" | gpg -q --batch --yes --passphrase-fd 0 --decrypt $ENCRYPTED_FILE | tar xjv > $PRIVATE_FILE
	done

	;;
    
    deps)
	sudo yum -y install gpg
	;;
    listkeys)
	gpg --list-keys
	;;

    genkeys)
	echo "Only do this if you don't have an existing GPG key"
	echo "  PRESS ENTER TO CONTINUE or CTRL-C to exit"
	read

	echo "Collecting input parameters for generating your GPG key"
	read -p "Enter your full name (First Last): " NAME
	read -p "Enter your email address (e.g. you@domain.com): " EMAIL
	while true; do
	    read -p "Enter your GPG comment (e.g. work): " COMMENT
	    echo
	    if [ "$COMMENT" == "" ]; then
		echo "ERROR: Empty comment not permitted"
		continue
	    else
		break
	    fi
	done

	while true; do 
	    read -p "Enter a password for your GPG key: " -s PASSWORD
	    echo
	    read -p "Verify the password for your GPG key: " -s VERIFY
	    echo

	    if [ "$PASSWORD" == "" ]; then
		echo "ERROR: Empty password not permitted"
		continue
	    fi

	    if [ "$PASSWORD" == "$VERIFY" ]; then
		break
	    else
		echo "ERROR: Password verification did not match... try again"
		continue
	    fi
	done

	echo "Generating your key.  This will take a few minutes"
	printf "Key-Type: DSA
Key-Length: 2048
Subkey-Type: ELG-E
Subkey-Length: 2048
Expire-Date: 0
Name-Real: %s
Name-Comment: %s
Name-Email: %s
Passphrase: %s
" "$NAME" "$COMMENT" "$EMAIL" "$PASSWORD" | gpg --gen-key --batch --yes

	echo "Your GPG data is found in ~/.gnupg"
	gpg --list-keys

	echo "Exporting your keys to ~/gnupg/backup for easy backup"
	echo "  Please backup these keys"
	gpg --armor --output $BACKUP_DIR/"$EMAIL".gpg.private --export-secret-keys "$EMAIL"
	gpg --armor --output $BACKUP_DIR/"$EMAIL".gpg.public --export "$EMAIL"

	echo "Exporting your public key file to $KEY_DIR/$EMAIL.gpg"
	gpg --armor --output $KEY_DIR/"$EMAIL".gpg --export "$EMAIL"

	echo
	echo "COMPLETE"
	echo
	echo "  IMPORTANT: Be sure to 'git add $KEY_DIR/$EMAIL.gpg'"
	echo
	echo "  To get access to encrypted documents, ask an existing keyholder"
	echo "    to decrypt the docs, encrypt the docs (using multi-party encrypt)"
	echo "    And then check the encrypted files into github"
	echo "  ./secure.sh decrypt"
	echo "  ./secure.sh encrypt"
	echo
	echo "  git add encrypted/*"
	echo "  git commit -m 'message'"
	echo "  git push"
	;;
    loadkeys)
	gpg --yes --import $KEY_DIR/*.gpg
	;;
    usage)
	echo "$USAGE"
	;;
    *)
	;;
esac

