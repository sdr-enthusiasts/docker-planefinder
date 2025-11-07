# sdr-enthusiasts/docker-planefinder

[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/planefinder/latest)](https://hub.docker.com/r/mikenye/planefinder)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running [PlaneFinder's](https://planefinder.net/)'s `pfclient`. Designed to work in tandem with [sdr-enthusiasts/docker-readsb-protobuf](https://github.com/sdr-enthusiasts/docker-readsb-protobuf). Builds and runs on `x86_64`, `386`, `arm64` and `arm32v7` (see below).

`pfclient` pulls ModeS/BEAST information from a host or container providing ModeS/BEAST data, and sends data to PlaneFinder.

For more information on what `pfclient` is, see here: <https://planefinder.net/sharing/client>.

## IMPORTANT NOTE FOR USERS ON PI5/libpthread.so.0

Planefinder client `5.0.161` will see the following error on startup:

```bash
error while loading shared libraries: libpthread.so.0: ELF load command address/offset not page
```

This, at least at the moment, is not something we can fix and will require the upstream developers to fix. Alternative, in [this issue](https://github.com/sdr-enthusiasts/docker-planefinder/issues/34) you can find a work around which involves switching to a different kernel.

## Supported tags and respective Dockerfiles

- `latest` (`master` branch, `Dockerfile`)
- Version and architecture specific tags available
- `development` (`dev` branch, `Dockerfile`, not recommended for production)

## Obtaining a PlaneFinder Share Code

First-time users should obtain a PlaneFinder Share Code.

In order to obtain a PlaneFinder Share Code, we will start a temporary container running `pfclient`, which will run through a configuration wizard and generate a share code.

To do this, run the command:

```shell
docker run \
    --rm \
    -it \
    --name pfclient_temp \
    --entrypoint /firstrun \
    -p 30053:30053 \
    ghcr.io/sdr-enthusiasts/docker-planefinder:latest
```

Once the container has started, you should see a message such as:

```text
2020-04-11 06:45:25.823307 [-] We were unable to locate a configuration file and have entered configuration mode by default. Please visit: http://172.22.7.12:30053 to complete configuration.
```

At this point, open a web browser and go to <http://dockerhost:30053>. Replace `dockerhost` with the IP address of your host running Docker. You won't be able to use the URL given in the log output, as the IP address given will be the private IP of the docker container.

In your browser, go through the configuration wizard. When finished, you'll be given a PlaneFinder Share Code. Save this in safe place.

You can now kill the container by pressing `CTRL-C`.

If you're not a first time user and are migrating from another installation, you can retrieve your sharing key by logging into your planefinder.net account, and going to "Your Receivers".

## Up-and-Running with `docker run`

```shell
docker run \
 -d \
 --rm \
 --name pfclient \
 -p 30053:30053 \
 -e TZ="YOURTIMEZONE" \
 -e BEASTHOST=YOURBEASTHOST \
 -e LAT=YOURLATITUDE \
 -e LONG=YOURLONGITUDE \
 -e SHARECODE=YOURSHARECODE \
 ghcr.io/sdr-enthusiasts/docker-planefinder:latest
```

You should obviously replace `YOURBEASTHOST`, `YOURLATITUDE`, `YOURLONGITUDE` and `YOURSHARECODE` with appropriate values.

For example:

```shell
docker run \
 -d \
 --rm \
 --name pfclient \
 -p 30053:30053 \
 -e TZ="Australia/Perth" \
 -e BEASTHOST=readsb \
 -e LAT=-33.33333 \
 -e LONG=111.11111 \
 -e SHARECODE=zg84632abhf231 \
 ghcr.io/sdr-enthusiasts/docker-planefinder:latest
```

## Up-and-Running with Docker Compose

```yaml
services:
  pfclient:
    image: ghcr.io/sdr-enthusiasts/docker-planefinder:latest
    container_name: pfclient
    restart: always
    ports:
      - 30053:30053
    environment:
      - TZ=Australia/Perth
      - BEASTHOST=readsb
      - LAT=-33.33333
      - LONG=111.11111
      - SHARECODE=zg84632abhf231
```

## Claiming Your Receiver

Once your container is up and running, you should claim your receiver.

1. Go to <https://www.planefinder.net/>
2. Create an account and/or sign in
3. Go to "Account" > "Manage Receivers"
4. Click "Add receiver" and enter your share code when prompted

## Runtime Environment Variables

There are a series of available environment variables:

| Environment Variable | Purpose                                                              | Default |
| -------------------- | -------------------------------------------------------------------- | ------- |
| `BEASTHOST`          | Required. IP/Hostname of a Mode-S/BEAST provider (dump1090/readsb)   |         |
| `BEASTPORT`          | Optional. TCP port number of Mode-S/BEAST provider (dump1090/readsy) | 30005   |
| `SHARECODE`          | Required. PlaneFinder Share Code                                     |         |
| `LAT`                | Required. Latitude of the antenna                                    |         |
| `LONG`               | Required. Longitude of the antenna                                   |         |
| `TZ`                 | Optional. Your local timezone                                        | GMT     |
| `RADAR_STICK`        | Use planefinder radar stick                                          | false   |
| `RADAR_STICK_DEVICE` | planefinder radar stick device address                               | /dev/ttyUSB0 |

## Ports

The following ports are used by this container:

- `30053` - `pfclient` web GUI. Suggest mapping this port for the web GUI.
- `30054` - `pfclient` "echo port". Suggest leaving this port unmapped.
- `30055` - `pfclient` beast output when using radar stick

## Plane Finder Radar Stick

To use the radar stick, add this to the compose yml:

```yaml
    device_cgroup_rules:
      # serial devices
      - 'c 188:* rwm'
    volumes:
      - /dev:/dev:ro
```

Also add `RADAR_STICK=true` to the environment variables in the yml.

## Logging

- All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting Help

You can [log an issue](https://github.com/sdr-enthusiasts/docker-planefinder/issues) on the project's GitHub.

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.
