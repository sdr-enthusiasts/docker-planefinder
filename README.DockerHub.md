# mikenye/planefinder

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/mikenye/docker-planefinder/Deploy%20to%20Docker%20Hub)](https://github.com/mikenye/docker-planefinder/actions?query=workflow%3A%22Deploy+to+Docker+Hub%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/mikenye/planefinder.svg)](https://hub.docker.com/r/mikenye/planefinder)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/planefinder/latest)](https://hub.docker.com/r/mikenye/planefinder)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running [PlaneFinder's](https://planefinder.net/)'s `pfclient`. Designed to work in tandem with [mikenye/readsb-protobuf](https://hub.docker.com/repository/docker/mikenye/readsb-protobuf). Builds and runs on `x86_64`, `386`, `arm64` and `arm32v7` (see below).

`pfclient` pulls ModeS/BEAST information from a host or container providing ModeS/BEAST data, and sends data to PlaneFinder.

For more information on what `pfclient` is, see here: <https://planefinder.net/sharing/client>.

## Documentation

Please [read this container's detailed and thorough documentation in the GitHub repository.](https://github.com/mikenye/docker-planefinder/blob/master/README.md)