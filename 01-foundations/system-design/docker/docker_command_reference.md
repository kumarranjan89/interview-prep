# Docker Command Reference

Location: `01-foundations/system-design/docker/docker-command-reference.md`

A quick-lookup cheat sheet for commands used across the other files in this folder. Grouped by task, not alphabetically.

---

## Images

```bash
docker build -t myapp:v1 .                  # build image from Dockerfile in current dir
docker build -t myapp:v1 -f Dockerfile.dev . # build using a specific Dockerfile
docker build --target build -t myapp:debug . # build only up to a named stage (multi-stage)
docker images                                # list local images
docker rmi myapp:v1                          # remove an image
docker image prune                           # remove dangling (untagged) images
docker image prune -a                        # remove all unused images
docker tag myapp:v1 myrepo/myapp:v1          # tag image for a registry
docker push myrepo/myapp:v1                  # push to registry
docker pull myrepo/myapp:v1                  # pull from registry
docker history myapp:v1                      # inspect layer history of an image
```

## Containers

```bash
docker run myapp:v1                          # run a container
docker run -d -p 3000:3000 myapp:v1          # run detached, map host:container port
docker run --name web -p 3000:3000 myapp:v1  # run with a custom container name
docker run -e KEY=value myapp:v1             # pass an environment variable
docker run -v mydata:/app/data myapp:v1      # mount a named volume
docker run -v $(pwd):/app myapp:v1           # bind mount current host dir
docker run -it myapp:v1 sh                   # run interactively with a shell
docker ps                                    # list running containers
docker ps -a                                 # list all containers (including stopped)
docker stop <container>                      # gracefully stop a container
docker kill <container>                      # force stop a container
docker start <container>                     # start a stopped container
docker restart <container>                   # restart a container
docker rm <container>                        # remove a stopped container
docker rm -f <container>                     # force remove a running container
docker container prune                       # remove all stopped containers
```

## Inspecting & Debugging

```bash
docker exec -it <container> sh               # open a shell inside a running container
docker exec -it <container> bash             # same, if bash is available
docker logs <container>                      # view container logs
docker logs -f <container>                   # follow logs live
docker logs --tail 100 <container>           # last 100 lines
docker inspect <container>                   # full JSON metadata (networks, volumes, env, etc.)
docker top <container>                       # running processes inside a container
docker stats                                 # live resource usage (CPU/mem) for all containers
docker diff <container>                      # filesystem changes since container started
```

## Networking

```bash
docker network ls                            # list networks
docker network create my-network             # create a custom network
docker network inspect my-network            # see connected containers, subnet, etc.
docker network connect my-network <container> # attach a running container to a network
docker network disconnect my-network <container>
docker network rm my-network                 # remove a network
docker run --network=my-network myapp:v1     # run a container on a specific network
```

## Volumes

```bash
docker volume ls                             # list volumes
docker volume create mydata                  # create a named volume
docker volume inspect mydata                 # see mount point, driver, etc.
docker volume rm mydata                      # remove a volume
docker volume prune                          # remove all unused volumes
```

## Docker Compose

```bash
docker-compose up                            # build (if needed) and start all services
docker-compose up -d                         # start in detached mode
docker-compose up --build                    # force rebuild before starting
docker-compose down                          # stop and remove containers, networks
docker-compose down -v                       # also remove named volumes
docker-compose ps                            # list services and their status
docker-compose logs -f <service>             # follow logs for one service
docker-compose exec <service> sh             # shell into a running service
docker-compose build                         # build images without starting containers
docker-compose restart <service>             # restart a single service
docker-compose stop                          # stop services without removing them
```

## Cleanup (use with care)

```bash
docker system df                             # disk usage summary (images, containers, volumes)
docker system prune                          # remove stopped containers, dangling images, unused networks
docker system prune -a                       # also remove all unused images (not just dangling)
docker system prune -a --volumes             # also remove unused volumes — destructive, check first
```

---

## Notes

- `docker exec` vs `docker run`: `exec` runs a command inside an **already running** container; `run` creates a **new** container from an image.
- `-d` (detached) vs no flag: without `-d`, the terminal attaches to the container's stdout — closing the terminal (without `-it`) can stop the container depending on the process.
- Prefer `docker compose` (space, v2 syntax, no hyphen) over `docker-compose` (v1, standalone binary) if using a recent Docker install — v2 is now bundled with Docker Desktop/Engine. Both are shown here as `docker-compose` since it's still widely seen in existing projects and CI configs.
- When in doubt about what's eating disk space, `docker system df` first, then targeted `prune` — avoid `--volumes` unless you're sure nothing important is unbacked-up.