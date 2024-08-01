# docker-gitea <!-- omit from toc -->
Docker compose setup to run a git server with a Gitea web frontend.

This setup assumes that you're already running:
  - A [Traefik reverse-proxy](https://github.com/znibb/docker-traefik)
  - An [Authentik](https://github.com/znibb/docker-authentik) Identity Provider

## Table of Contents <!-- omit from toc -->
- [1. Docker Setup](#1-docker-setup)
- [2. Host setup](#2-host-setup)
- [3. Client setup](#3-client-setup)
- [4. Authentik setup](#4-authentik-setup)
- [5. Gitea setup](#5-gitea-setup)

## 1. Docker Setup
1. Initialize config by running init.sh: `./init.sh`
2. Input personal information into `.env`
3. Run `docker compose up` and check logs

## 2. Host setup
1. Create a `git` user on the host: `sudo adduser git`
2. Take note of the `UID` and `GID` created (can also be viewed with `id git`), enter the respective values in `.env`
3. Create a Gitea Host Key for use with ssh: `sudo -u git ssh-keygen -t ed25519 -C "Gitea Host Key"`
4. Add the recently created key to `authorized_keys` for the git user: `sudo -u git cat /home/git/.ssh/id_ed25519.pub | sudo -u git tee -a /home/git/.ssh/authorized_keys`
5. Fix permissions for `authorized_keys` file: `sudo -u git chmod 600 /home/git/.ssh/authorized_keys`
6. Create the file `/usr/local/bin/gitea` to use as a fake gitea command to forward requests to the host to the gitea container: `sudo vim /usr/local/bin/gitea`
7. Enter:
    ```
    #!/bin/sh
    ssh -p 2222 -o StrictHostKeyChecking=no git@127.0.0.1 "SSH_ORIGINAL_COMMAND=\"$SSH_ORIGINAL_COMMAND\" $0 $@"
    ```
8. Make the recently created file executable: `sudo chmod +x /usr/local/bin/gitea`

You will now be able to clone repositories via ssh and be forwarded from the host to the container.

## 3. Client setup
1. Go to your desired client PC and go to your `~/.ssh/` folder (if you don't have one and need to create it make sure it has 600 permissions)
2. Create a key pair for gitea use: `ssh-keygen -t ed25519 -C "USER@HOST" -f gitea`
3. Open/create a `config` file and add the following section to it:
  ```
  host git.DOMAIN.COM
    HostName git.DOMAIN.COM
    Port PORT
    User git
    IdentityFile ~/.ssh/gitea
  ```
4. Make sure your router has the port number PORT forwarded to your host machine
5. Go to `https://git.DOMAIN.COM` in your browser, log in and go to `Settings->SSH / GPG Keys`
6. Click `Add key`
7. Enter a `Key Name` similar to the -C directive used above
8. Paste the contents of `gitea.pub` into the `Content` field
9.  Click `Add Key`
10. Locate your key under `Manage SSH Keys` and click `Verify`
11. Copy the command suggested and replace the `-f` directive with your recently generated private key
12. Paste the results in the `Armored SSH signature` field and press `Verify`

You have now configured SSH access for your user

## 4. Authentik setup
1. Open the Authentik Admin Interface
2. Go to `Directory->Groups`
3. Create the following groups:
  - `Gitea Admin`
  - `Gitea Restricted`
  - `Gitea User`
4.  Go to `Customization->Property Mappings` and click `Create`
5.  Select `Scope Mapping` and click `Next`
6.  Set the `Name` to `Gitea Profile` and the `Scope name` to `gitea`
7.  Set `Expression` to the following:
  ```
  gitea_claims = {}
  if request.user.ak_groups.filter(name="Gitea User").exists():
      gitea_claims["gitea"]= "user"
  if request.user.ak_groups.filter(name="Gitea Admin").exists():
      gitea_claims["gitea"]= "admin"
  if request.user.ak_groups.filter(name="Gitea Restricted").exists():
      gitea_claims["gitea"]= "restricted"

  return gitea_claims
  ```
8. Go to `Applications->Providers` and click `Create`
9.  Select`OAuth2/OpenID Provider` and click `Next`
10. Enter the following:
  - Name: `Gitea Provider`
  - Authorization flow: implicit-consent
11. Take note of `Client ID` and `Client Secret`, you will use these later in the Gitea setup
12. Expand `Advanced protocol settings` and go to `Scopes`
13. Ensure the following scopes are highlighted:
  - `authentik default OAuth Mapping: OpenID 'email'`
  - `authentik default OAuth Mapping: OpenID 'openid'`
  - `authentik default OAuth Mapping: OpenID 'profile'`
  - `Gitea Profile` (that you created earlier)
14. Under `Subject mode` select `Based on the User's username`
15. Click `Finish`
16. Go to `Applications->Applications` and click `Create`
17. Enter `Name`/`Slug` as `Gitea`/`gitea` and for `Provider` select the recently created `Gitea Provider`
18. Click `Create`

## 5. Gitea setup
1. Go to `https://git.DOMAIN.COM` and you will be prompted to set up your initial user/admin account
2. Go to `https://git.DOMAIN.COM/admin/auths` and click `Add Authentication Source`
3. Enter the following:
  - Authentication Type: `OAuth2`
  - Authentication Name: `Authentik`
  - OAuth2 Provider: `OpenID Connect`
  - Client ID: As per the [Authentik setup](#4-authentik-setup)
  - Client Secret: As per the [Authentik setup](#4-authentik-setup)
  - Icon URL: `https://auth.DOMAIN.COM/static/dist/assets/icons/icon.svg`
  - OpenID Connect Auto Discovery URL: `https://auth.DOMAIN.COM/application/o/gitea/.well-known/openid-configuration` (Note: The `gitea` part has to match the application slug set up in Authentik)
  - Additional Scopes: `email profile gitea`
  - Required Claim Name: `gitea`
  - Claim name providing group names for this source: `gitea`
  - Group Claim value for administrator users: `admin`
  - Group Claim value for restricted users: `restricted`
4. Click `Add Authentication Source` at the bottom, above the `Tips` section