# Integrator

An integration tool using n8n.

## n8n

http://n8n.io

## n8n basic authentication

Authentication is required to operate the n8n editor. By default, it is `user: user`,` password: password`. This can be
changed in [n8n_config.json](n8n_config.json).

## Before building

### Fork the repos

This integrator is spread across two repositories. You should fork them.

* The integrator: https://github.com/Mulugruntz/integrator-n8n
* The backups: https://github.com/Mulugruntz/integrator-n8n-backups

Let's suppose you forked them to https://github.com/USERNAME.

### Clone the repos

In a terminal, execute the following:

```shell
mkdir integrator && cd integrator
git clone https://github.com/USERNAME/integrator-n8n.git integrator-n8n
git clone https://github.com/USERNAME/integrator-n8n-backups.git integrator-n8n-backups
```

And think about editing the `Dockerfile`'s `GIT_BACKUP_REPO` to put your own.

```shell
cd integrator-n8n
sed -i 's,git@github.com:Mulugruntz/integrator-n8n-backups.git,git@github.com:USERNAME/integrator-n8n-backups.git,g' Dockerfile
```

### Create Deploy keys for the backups

#### First time

In a terminal, generate new SSH keys:

```shell
cd integrator-n8n
./init.sh
```

Copy the public key.

Go to https://github.com/USERNAME/integrator-n8n-backups/settings/keys/new and paste the public key there. Give it the
title you want, such as `n8n automatic backup`. If you want to write new backups, you should `Allow write access`.

#### If the keys are already generated

Give your collaborators the content of [decrypt_key.secret](decrypt_key.secret). This way, when they'll build their own
image and deploy their own container, they will reuse the common SSH keys, allowing their n8n instance to read/write
your backup repository.

### Change the backup Git User

In the file `integrator-n8n-backups/workflows/1.json`, change the values of `GIT_USER_EMAIL` and `GIT_USER_NAME` to
match the ones of the account with the Deploy keys.

In a terminal (**Change `"newuser@name.com"` and `"Account name"`!!!**):

```shell
cd integrator-n8n-backups/workflows
echo "$(jq '(.nodes[].parameters.values.string[]? | select(.name == "GIT_USER_EMAIL") | .value) = "newuser@name.com"' 1.json)" > 1.json
echo "$(jq '(.nodes[].parameters.values.string[]? | select(.name == "GIT_USER_NAME") | .value) = "Account name"' 1.json)" > 1.json
```

Also think about changing the `README.md` to target your fork instead
(**Change `USERNAME` and `@Bot Name`!!!**):

```shell
cd integrator-n8n-backups
sed -i 's,https://github.com/Mulugruntz/integrator-n8n,https://github.com/USERNAME/integrator-n8n,g' README.md 
sed -i 's,https://github.com/Mulugruntz,https://github.com/USERNAME,g' README.md 
sed -i 's/@Mulugruntz/@Bot Name/g' README.md
```

## How to build and run

Run the following commands:

1. Initialize the decrypt key.

   ```shell
   echo '<decrypt_key>' > decrypt_key.secret
   git update-index --skip-worktree decrypt_key.secret
   ```
2. Build and run.

   ```shell
   docker-compose up --force
   ```

## What is the Decrypt key?

Our automation bot (`<bot_name>`) has access to our GitHub repository.

He has SSH keys and the public key is accepted by GitHub. In order to have it work, it needs the private key. For
security reason, the private key was encrypted.

#### Build a new SSH key and encrypt it

1. Make sure you have OpenSSL >= 1.1.1 (necessary for `-iter`).

    ```shell
    $> openssl version
    OpenSSL 1.1.1l  24 Aug 2021 (Library: OpenSSL 1.1.1i  8 Dec 2020)
    ```

2. Create and Encrypt the key.

    ```shell
    mkdir ssh
    ssh-keygen -f ssh/id_rsa -N ''
    tar cz ssh | openssl enc -aes-256-cbc -iter 10000 -pass 'pass:<decrypt_key>' -e > ssh.tar.gz.enc
    ```

#### Decrypt the key

```shell
mkdir -p output_dir
openssl enc -iter 10000 -pass 'pass:<decrypt_key>' -aes-256-cbc -d -in ssh.tar.gz.enc | tar xz -C output_dir
```
