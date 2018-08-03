# image-builder-rpi64
[![Build Status](https://travis-ci.org/DieterReuter/image-builder-rpi64.svg?branch=master)](https://travis-ci.org/DieterReuter/image-builder-rpi64)

This repo builds the SD card image with HypriotOS for the Raspberry Pi 3 in 64bit.
You can find released versions of the SD card image here in the GitHub
releases page. To build this SD card image we have to

 * take the files for the root filesystem from [`os-rootfs`](https://github.com/hypriot/os-rootfs)
 * take the empty raw filesystem from [`image-builder-raw`](https://github.com/hypriot/image-builder-raw) with the two partitions
 * add Hypriot's Debian repos
 * install the Raspberry Pi kernel from [`rpi64-kernel`](https://github.com/dieterreuter/rpi64-kernel)
 * install Docker tools Docker Engine, Docker Compose and Docker Machine

Here is an example how all the GitHub repos play together:

![Architecture](http://blog.hypriot.com/images/hypriotos-xxx/hypriotos_buildpipeline.jpg)

## Contributing

You can contribute to this repo by forking it and sending us pull requests.
Feedback is always welcome!

## Installing the Image
The team at [Hypriot](https://blog.hypriot.com) have provided a wonderful tool called [Flash](https://github.com/hypriot/flash).  Check out the Readme at their Github Repo for more information on how to use the image.

### Building

Building this image requires Travis-CI.  Local building isn't supported or recommended.

There are two env variables that must be set in Travis-CI:
- GITHUB_TOKEN
- GITHUB_OAUTH_TOKEN

## Deployment

After the Travis build finishes, open the GitHub release of the version you just created and fill it with relevant changes and links to resolved issues.

## Resources
This project uses [GHR](https://github.com/tcnksm/ghr/) to push releases from Travis to Github.

## License

MIT - see the [LICENSE](./LICENSE) file for details.
