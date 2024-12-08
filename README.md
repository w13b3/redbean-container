# redbean-container  <sub><sup>_redbean in a container_<sup><sub>

This project uses Docker [Bake].  


## How to build
> Prerequisites:  
> - Recent version of [Docker] installed  
> - Docker [BuildKit] installed (this can be a plugin on your system)  

Docker Bake can use a [remote] Bake file definition to locally build an image.  
Build an image with the following command:  
```shell
docker buildx bake https://github.com/w13b3/redbean-container.git
```


### The result
Once the build is completed, the tag `redbean:optlinux` is given to the image.  
The [scratch] based image contains the redbean binary, build with the `optlinux` mode, using the latest commit to [Cosmopolitan] default branch.  


### How to use
Start the image with the following command:  
```shell
docker run -it -p 9090:8080 redbean:optlinux
```
The redbean process in the container is now serving the default website.  
Using a browser the website can be visited at http://127.0.0.1:9090/  


## Customize the build
You can [override variable] defaults set in the Bake file using environment variables.  


### Different modes
Cosmopolitan provides a variety of build modes which result in different binaries.  
This project uses `optlinux` as the default mode to build the redbean binary.  
There are other modes, including but not limited to: `tinylinux`, `asan` or `rel`.  

The following example sets the `MODE` variable to `opt`, overriding the default `MODE` variable.  
```shell
MODE=opt docker buildx bake https://github.com/w13b3/redbean-container.git
```
Using `MODE=opt` an image with the tag `redbean:opt` is created after a successful build.  


### Previous versions
It is possible to build an image that includes a previous version of redbean.  
To do this, a full SHA of the Cosmopolitan commit is needed.  

The following command overrides the `REPO_SHA` variable with a full SHA to build an image containing redbean [v2.0.1].  
```shell
REPO_SHA="42b34c26f8099658386fc867c49b0b8e59993415" docker buildx bake https://github.com/w13b3/redbean-container.git
```
When the build is successful an image with the tag `redbean:optlinux-42b34c` is available.  


## Build other binaries
The [Cosmopolitan] repository offers other tools that can be built.  
Using this project, another binary can be built by setting the `TARGET_PATH` variable.

```shell
TARGET_PATH=/tool/hello/hello docker buildx bake https://github.com/w13b3/redbean-container.git
```
With a successful build the image with the tag `hello:optlinux` is created.  
The filename of the path given to `TARGET_PATH` becomes the name of the image.  

Build other tools by setting the `TARGET_PATH` paths with:  
- [/tool/viz/life](https://github.com/jart/cosmopolitan/blob/master/tool/viz/life.c)  
- [/tool/build/pledge](https://github.com/jart/cosmopolitan/blob/master/tool/build/pledge.c)
- [/third_party/python/python3](https://github.com/jart/cosmopolitan/blob/master/third_party/python/python3.c)  


## Motivation
> tl;dr: To learn how to containerize software  

[Cosmopolitan] is an awesome project and [redbean] is a very capable web server.  
While writing this, the latest version of redbean (v2.2) was released on [02-Nov-2022].  
In the meantime [really] [cool] [features] were added to the source of redbean.  
But to use these features, redbean must be built from source.  

Instead of using [containerized][kissgyorgy] software I wanted to learn how to containerize software.  
I wanted to know the best practices regarding containerization and apply them.  
I wanted to distribute images.  
And I also wanted to use the newest available features in redbean.  
So I decided to combine the learning goals into this project.  


[02-Nov-2022]: https://github.com/jart/cosmopolitan/commit/5e60e5ad107f0b32d16263ef02dc5090861dc664
[really]: https://github.com/jart/cosmopolitan/commit/d3ff48c63f89060844dcfa80f0526b2534dfd56f
[cool]: https://github.com/jart/cosmopolitan/commit/d50064a779625c4f0f3c4e972b821c2f696cfbad
[features]: https://github.com/jart/cosmopolitan/commit/d0d027810a87d091f1f7ced1351e59edf05bd2eb


## Acknowledgements
[jart], The creator of the [Cosmopolitan] project which includes the [redbean] source code.  
[redbean-docker][kissgyorgy], The repository that containerize pre-build redbean binaries.  


## License
See [LICENSE](./LICENSE)  


### Licenses of included or used software
See https://redbean.dev/#legal  
See [Cosmopolitan/LICENSE](https://github.com/jart/cosmopolitan/blob/master/LICENSE)  

Please adhere to the licenses of the other included or used software.  


[Bake]: https://docs.docker.com/build/bake/
[scratch]: https://hub.docker.com/_/scratch
[Docker]: https://docs.docker.com/get-docker/
[BuildKit]: https://docs.docker.com/build/buildkit/
[remote]: https://docs.docker.com/build/bake/remote-definition/
[override variable]: https://docs.docker.com/build/bake/reference/#variable
[v2.0.1]: https://github.com/jart/cosmopolitan/commit/42b34c26f8099658386fc867c49b0b8e59993415
[Alpine]: https://hub.docker.com/_/alpine
[jart]: https://justine.lol/
[pkulchenko]: https://github.com/pkulchenko
[fullmoon]: https://github.com/pkulchenko/fullmoon
[Cosmopolitan]: https://github.com/jart/cosmopolitan
[redbean]: https://redbean.dev/
[redbean.c]: https://github.com/jart/cosmopolitan/blob/master/tool/net/redbean.c
[kissgyorgy]: https://github.com/kissgyorgy/redbean-docker
