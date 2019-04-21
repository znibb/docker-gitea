# Gitea Docker image

## Before starting
1. Download stack file: `wget https://raw.githubusercontent.com/znibb/docker-gitea/master/docker-stack.yml`
2. Set database password: `echo "PASSWORD_HERE" | docker secret create gitea_db_passwd -`

## Starting
Deploy: `docker stack deploy -c docker-stack.yml gitea`
