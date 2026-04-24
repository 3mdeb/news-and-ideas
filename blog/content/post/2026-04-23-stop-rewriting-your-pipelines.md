---
title: 'Stop rewriting your pipelines - achieving CI portability with Docker and Taskfile'
abstract: 'After years of reacting to CI platform changes and rewriting pipeline definitions,
          we decided to research a better approach. This post describes our evaluation of
          different solutions and why we settled on treating CI systems as interchangeable
          orchestration layers, with build logic living in portable Docker containers
          orchestrated by Taskfile. We plan to adopt this approach more widely and see
          how it holds up in practice.'
cover: /covers/docker_task.png
author: maciej.pijanowski
layout: post
private: false      # if cannot be public, set to: true
published: true    # if ready or needs local-preview, change to: true
date: 2026-04-24    # update also in the filename!
archives: "2026"

tags:               # check: https://blog.3mdeb.com/tags/
  - CI
  - docker
  - build
  - devops
categories:
  - Miscellaneous

---

## Introduction

We've been working with CI systems for years now, and frankly, we're exhausted
from rewriting pipelines.

It all started with [Jenkinsfiles][jenkins] a couple of years ago. Jenkins
served us well for a while, but maintaining Jenkins infrastructure became a
burden of its own. Then we moved to [Travis CI][travis] back when it was free
for open-source projects - it seemed like a great deal, and we invested time
learning the syntax and getting our builds working smoothly. Then Travis
[changed their pricing model][travis-pricing] and the free tier for open-source
essentially disappeared.

At some point we switched to [GitLab][gitlab] with GitLab-CI and self-hosted
runners. New syntax, new concepts, new configuration files. That worked for a
while, but then GitLab started [introducing more and more limits][gitlab-limits]
on their free tier, pushing us toward more expensive plans. Meanwhile, some
projects needed to live on GitHub anyway. So we ended up with a mixture of
public [GitHub Actions][github-actions] runners and self-hosted ones. Yet
another set of workflow files to maintain.

Now? We're running GitHub Actions for some projects, self-hosted
[Gitea Actions][gitea] for others, and self-hosted [Woodpecker][woodpecker]
pipelines for yet another set. Three different CI systems, three different
syntaxes, all doing essentially the same thing - building and testing our code.

[jenkins]: https://www.jenkins.io/
[travis]: https://www.travis-ci.com/
[travis-pricing]: https://blog.travis-ci.com/2020-11-02-travis-ci-new-billing
[gitlab]: https://about.gitlab.com/
[gitlab-limits]: https://about.gitlab.com/blog/2022/03/24/efficient-free-tier/
[github-actions]: https://github.com/features/actions
[gitea]: https://about.gitea.com/
[woodpecker]: https://woodpecker-ci.org/

Looking back, we realize we've been constantly **reacting** to ecosystem
changes. A pricing model shifts, a platform loses community trust, a new
self-hosted option emerges that better fits our infrastructure - and suddenly
we're rewriting pipelines again.

Recently, we decided to step back and think about this differently. What if we
stopped reacting and started building resilience? What if the CI platform was
just a thin layer that triggers builds and collects artifacts, while the actual
compilation, testing, and packaging lived somewhere truly independent?

We've come to accept that we might lose a feature or two by not fully embracing
each platform's capabilities. But at this point, we care more about
independence from the provider and the ability to reproduce pipelines locally
than about having the fanciest CI features.

In this post, we'll describe our journey toward finding a solution that lets us
run the same build locally as in CI, without locking ourselves into yet another
platform.

## The plan

After some research and experimentation, we settled on these goals:

- Find a way to define build steps that execute identically on a developer's
  laptop and in any CI system
- Keep each build step isolated (in a container) with explicit dependencies
- Make it possible to pass artifacts between steps (compile in one container,
  test in another)
- Avoid complex tools that might themselves become abandonware
- Keep it simple enough that end users can build our firmware from source
  without learning specialized tooling
- Accept losing some CI-specific features in exchange for true portability

## What we tried

### Dagger - too much complexity for our needs

<img src="/img/ci-portability/dagger-logo.svg" alt="Dagger"
  style="height: 60px; margin: 1em 0;">

[Dagger][dagger] lets you write pipelines as code in Python, Go, or TypeScript.
The same pipeline runs locally and in CI, which is exactly what we're looking
for.

[dagger]: https://dagger.io/

```python
@object_type
class Pipeline:
    @function
    async def build(self, src: dagger.Directory) -> dagger.Directory:
        return (
            dag.container()
            .from_("gcc:latest")
            .with_directory("/src", src)
            .with_workdir("/src")
            .with_exec(["make", "OUTPUT_DIR=/output"])
            .directory("/output")
        )

    @function
    async def test(self, build: dagger.Directory, scripts: dagger.Directory) -> str:
        return await (
            dag.container()
            .from_("debian:latest")
            .with_directory("/output", build)
            .with_directory("/scripts", scripts)
            .with_exec(["/scripts/test.sh", "/output/hello"])
            .stdout()
        )
```

The caching looks excellent, and the strong typing should catch errors early.
However, Dagger requires running a local engine (which is itself a Docker
container), understanding its GraphQL-based architecture, and learning SDK
conventions. For organizations with dedicated infrastructure teams, this might
work well. For us, the complexity seems hard to justify, and we're not
comfortable depending on a VC-funded startup for critical build infrastructure -
we've learned that lesson before.

### Earthly - great tool, uncertain future

<img src="/img/ci-portability/earthly-logo.png" alt="Earthly"
  style="height: 60px; margin: 1em 0;">

[Earthly][earthly] uses Dockerfile-like syntax adapted for build pipelines,
which makes the learning curve gentle:

[earthly]: https://earthly.dev/

```earthfile
build:
    FROM gcc:latest
    COPY src /src
    WORKDIR /src
    RUN make OUTPUT_DIR=/output
    SAVE ARTIFACT /output/* AS LOCAL build/

test:
    FROM debian:latest
    COPY +build/ /output/
    COPY scripts /scripts
    RUN /scripts/test.sh /output/hello
```

The syntax is familiar, and the reproducibility guarantees are solid.
Unfortunately, Earthly [shut down][earthly-shutdown]. The open-source tool
still exists, but without ongoing corporate support, we're not confident about
long-term maintenance and bug fixes. This is exactly the kind of dependency
risk we were trying to avoid.

[earthly-shutdown]: https://earthly.dev/blog/shutting-down-earthfiles-cloud/

### Docker Compose - wrong tool for the job

[Docker Compose][docker-compose] could theoretically be repurposed for build
pipelines:

[docker-compose]: https://docs.docker.com/compose/

```yaml
services:
  build:
    image: gcc:latest
    volumes:
      - ./src:/src:ro
      - ./build:/output
    working_dir: /src
    command: make OUTPUT_DIR=/output

  test:
    image: debian:latest
    volumes:
      - ./build:/output:ro
      - ./scripts:/scripts:ro
    command: /scripts/test.sh /output/hello
    depends_on:
      build:
        condition: service_completed_successfully
```

This technically works, but it feels awkward. Docker Compose is designed for
long-running services that communicate over networks, not for sequential build
steps passing files around.

### Nix - powerful but a steep learning curve

<img src="/img/ci-portability/nix-logo.svg" alt="Nix"
  style="height: 60px; margin: 1em 0;">

[Nix][nix] deserves mention because it solves the reproducibility problem in a
fundamentally different way. Instead of
containerizing build environments, Nix provides hermetic builds through its
purely functional package management approach. Every dependency is explicitly
declared and pinned, and builds are reproducible down to the byte.

[nix]: https://nixos.org/

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    packages.x86_64-linux.hello = pkgs.stdenv.mkDerivation {
      name = "hello";
      src = ./src;
      buildPhase = "make OUTPUT_DIR=$out";
      installPhase = "true";  # already installed in buildPhase
    };

    checks.x86_64-linux.test = pkgs.runCommand "test" {
      buildInputs = [ self.packages.x86_64-linux.hello ];
    } ''
      ${./scripts/test.sh} ${self.packages.x86_64-linux.hello}/hello
      touch $out
    '';
  };
}
```

The reproducibility guarantees are excellent, and the Nix ecosystem is mature
with strong community support. However, we decided against it for a few reasons.
First, adopting Nix would require bringing Nix knowledge to the entire team -
it's a different paradigm with its own language and concepts, and the learning
curve is steep. Second, we already have all of our build environments defined in
containers, and that investment would largely go to waste. Third, while Nix
itself is well-established, integrating it into various CI systems still
requires some effort, and we'd be trading one set of platform-specific
configurations for another.

For teams already using Nix or starting fresh, it's worth serious consideration.
For us, containers are the pragmatic choice given where we are today.

### Taskfile with Docker - our current best match

<div style="display: flex; gap: 2em; align-items: center; margin: 1em 0;">
  <img src="/img/ci-portability/taskfile-logo.svg" alt="Taskfile"
    style="height: 60px;">
  <img src="/img/ci-portability/docker-logo.png" alt="Docker"
    style="height: 60px;">
</div>

Finally, we landed on combining [Taskfile][taskfile] with [Docker][docker], and
this is the approach that best matches our needs based on our research.
[Task][taskfile] (the tool behind Taskfile) is a modern, cross-platform task
runner with a simple YAML syntax. By itself, it's just a nicer Make alternative.
But when we started wrapping Docker commands in tasks, it seemed to tick most of
our boxes.

[taskfile]: https://taskfile.dev/
[docker]: https://www.docker.com/

Here's basic sample setup:

```yaml
version: '3'

vars:
  OUTPUT_DIR: build

tasks:
  build:
    desc: Compile the program
    cmds:
      - mkdir -p {{.OUTPUT_DIR}}
      - docker run --rm
          -v {{.PWD}}/src:/src:ro
          -v {{.PWD}}/{{.OUTPUT_DIR}}:/output
          -w /src
          gcc:latest
          make OUTPUT_DIR=/output

  test:
    desc: Run tests
    deps: [build]
    cmds:
      - docker run --rm
          -v {{.PWD}}/{{.OUTPUT_DIR}}:/output:ro
          -v {{.PWD}}/scripts:/scripts:ro
          debian:latest
          /scripts/test.sh /output/hello
```

It's readable, requires no specialized tools beyond Docker and the Task binary,
and we can run `task build` on any developer's laptop with exactly the same
result as in CI. This is what we wanted all along - a pipeline execution tool
that starts sequential tasks in different containers, passes artifacts between
them, and works the same way locally as in any CI system.

## Making it cleaner with a container abstraction

The basic approach worked, but we found ourselves repeating Docker command
structures across many tasks. To address this, we created a reusable internal
task that handles container execution:

```yaml
version: '3'

vars:
  OUTPUT_DIR: build

tasks:
  build:
    desc: Compile the program
    cmds:
      - mkdir -p {{.OUTPUT_DIR}}
      - task: _run
        vars:
          IMAGE: gcc:latest
          VOLUMES: "{{.PWD}}/src:/src:ro,{{.PWD}}/{{.OUTPUT_DIR}}:/output"
          WORKDIR: /src
          COMMAND: "make OUTPUT_DIR=/output"

  test:
    desc: Run tests
    deps: [build]
    cmds:
      - task: _run
        vars:
          IMAGE: debian:latest
          VOLUMES: "{{.PWD}}/{{.OUTPUT_DIR}}:/output:ro,{{.PWD}}/scripts:/scripts:ro"
          COMMAND: "/scripts/test.sh /output/hello"

  _run:
    internal: true
    cmds:
      - |
        MOUNT_ARGS=""
        for vol in $(echo "{{.VOLUMES}}" | tr ',' '\n'); do
          MOUNT_ARGS="$MOUNT_ARGS -v $vol"
        done

        ENV_ARGS=""
        if [ -n "{{.ENV}}" ]; then
          for env in $(echo "{{.ENV}}" | tr ',' '\n'); do
            ENV_ARGS="$ENV_ARGS -e $env"
          done
        fi

        docker run --rm \
          {{if .WORKDIR}}-w {{.WORKDIR}}{{end}} \
          $MOUNT_ARGS \
          $ENV_ARGS \
          {{.IMAGE}} \
          sh -c "{{.COMMAND}}"
```

Now each task declares its requirements declaratively: which image to use, what
to mount, and what command to execute. The `_run` task handles all the
mechanical details. This made our Taskfiles much cleaner and less error-prone.

## Handling complex build logic

Putting all build logic directly in the COMMAND parameter works for simple
cases, but has limitations. Here are a few strategies for handling this
complexity.

### Multi-line shell scripts in the command

For moderately complex logic, we can embed shell scripts directly:

```yaml
compile:
  cmds:
    - task: _run
      vars:
        IMAGE: gcc:latest
        VOLUMES: "{{.PWD}}/src:/src:ro,{{.PWD}}/build:/output"
        WORKDIR: /src
        COMMAND: |
          set -euo pipefail

          if [ ! -f Makefile ]; then
            echo "Error: Makefile not found"
            exit 1
          fi

          echo "Compiling..."
          make OUTPUT_DIR=/output

          echo "Build succeeded"
          ls -lh /output
```

### Mounting separate script files

For more complex logic, we can maintain scripts as separate files and mount
them into the container:

```yaml
tasks:
  test:
    cmds:
      - task: _run
        vars:
          IMAGE: debian:latest
          VOLUMES: "{{.PWD}}/build:/output:ro,{{.PWD}}/scripts:/scripts:ro"
          COMMAND: "/scripts/test.sh /output/hello"
```

The `test.sh` script can then contain arbitrary complexity while remaining
version-controlled and testable on its own:

```sh
#!/bin/sh
set -eu

BINARY="${1:-/output/hello}"

echo "Running tests..."

# Check binary exists
if [ ! -f "$BINARY" ]; then
    echo "FAIL: Binary not found at $BINARY"
    exit 1
fi

# Check binary is executable
if [ ! -x "$BINARY" ]; then
    echo "FAIL: Binary is not executable"
    exit 1
fi

# Run and check output
OUTPUT=$("$BINARY")
EXPECTED="Hello from portable CI pipeline!"

if [ "$OUTPUT" = "$EXPECTED" ]; then
    echo "PASS: Output matches expected"
else
    echo "FAIL: Output mismatch"
    echo "  Expected: $EXPECTED"
    echo "  Got: $OUTPUT"
    exit 1
fi

echo "All tests passed!"
```

### Go for complex build logic

For even more complex scenarios, we're also considering Go as an alternative to
shell scripts. Go compiles to a single static binary with no runtime
dependencies, making it easy to distribute and run in any container. The
advantages over shell scripts are significant:

- **Type safety**: Errors are caught at compile time, not runtime
- **Better error handling**: No more checking `$?` after every command
- **Rich standard library**: HTTP clients, JSON parsing, file operations,
  concurrency - all built in
- **Cross-platform**: Write once, compile for any OS/architecture
- **Testable**: Unit tests for build logic, not just integration tests
- **Maintainable**: Refactoring tools, IDE support, clear structure

A build script in Go could handle complex tasks like downloading dependencies,
verifying checksums, generating code - all with proper error handling and
logging. The compiled binary can be included in the container image or mounted
alongside shell scripts.

We haven't fully explored this approach yet, but it's on our radar for build
logic that outgrows shell scripts.

## Sharing patterns across projects

Taskfile supports [including task definitions from remote URLs][taskfile-includes],
which is useful for standardizing patterns across projects. Note that remote
taskfiles are currently an [experimental feature][taskfile-remote] and need to
be enabled by setting `TASK_X_REMOTE_TASKFILES=1`. Adding a checksum pins the
remote file to a specific version and skips the confirmation prompt in CI.

[taskfile-includes]: https://taskfile.dev/usage/#including-other-taskfiles
[taskfile-remote]: https://taskfile.dev/experiments/remote-taskfiles

```yaml
version: '3'

includes:
  docker:
    taskfile: https://raw.githubusercontent.com/3mdeb/taskfiles/main/docker.yml
    checksum: 0dec15ba3fb237a24b5cc4e4f56d23613d071ddc7487eb8e4307969dd1c4a1ac

tasks:
  build:
    cmds:
      - task: docker:run
        vars:
          IMAGE: gcc:latest
          VOLUMES: "{{.PWD}}/src:/src:ro,{{.PWD}}/build:/output"
          WORKDIR: /src
          COMMAND: "make OUTPUT_DIR=/output"
```

The remote [`docker.yml`][docker-yml] contains the reusable `run` task:

[docker-yml]: https://github.com/3mdeb/taskfiles/blob/main/docker.yml

```yaml
version: '3'

tasks:
  run:
    desc: Run a command in a Docker container
    internal: true
    cmds:
      - |
        MOUNT_ARGS=""
        for vol in $(echo "{{.VOLUMES}}" | tr ',' '\n'); do
          MOUNT_ARGS="$MOUNT_ARGS -v $vol"
        done

        ENV_ARGS=""
        if [ -n "{{.ENV}}" ]; then
          for env in $(echo "{{.ENV}}" | tr ',' '\n'); do
            ENV_ARGS="$ENV_ARGS -e $env"
          done
        fi

        docker run --rm \
          {{if .WORKDIR}}-w {{.WORKDIR}}{{end}} \
          $MOUNT_ARGS \
          $ENV_ARGS \
          {{.IMAGE}} \
          sh -c "{{.COMMAND}}"
```

Taskfile caches these remote includes locally, so builds still work offline
after the initial download.

## Integrating with CI systems

This is where the payoff becomes clear. The Taskfile defines our actual build
logic, and CI platforms just trigger it and collect artifacts. Here's what our
CI configurations look like now:

**GitLab CI:**

```yaml
image: alpine:latest

before_script:
  - apk add --no-cache docker-cli curl
  - sh -c "$(curl -sL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

build:
  services:
    - docker:dind
  script:
    - task build
  artifacts:
    paths:
      - build/
```

**GitHub Actions:**

```yaml
name: Build
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: arduino/setup-task@v1
      - run: task build
      - uses: actions/upload-artifact@v3
        with:
          name: firmware
          path: build/
```

**Gitea Actions:**

```yaml
name: Build
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: arduino/setup-task@v1
      - run: task build
```

**Woodpecker:**

```yaml
steps:
  build:
    image: alpine:latest
    commands:
      - apk add --no-cache docker-cli curl
      - sh -c "$(curl -sL https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
      - task build
```

The CI-specific code is minimal and nearly identical across platforms. If we
need to migrate to yet another system - and given our history, we probably
will - we only need to write a thin wrapper that installs Task and invokes the
right tasks. The actual build logic stays untouched.

## Potential issues to be aware of

There are a few issues worth mentioning when adopting this approach.

### Docker-in-Docker permissions

Running Docker commands inside CI containers requires some setup. On GitLab CI,
you need to add the `docker:dind` service and make sure the job has access to
the Docker socket. On GitHub Actions (public runners) Docker is already
available. On Gitea and Woodpecker self-hosted runners, you need to configure
the runner to allow Docker access.

### Volume mount paths

Volume mount paths need to be absolute and consistent between the host and
container. Using `{{.PWD}}` in Taskfile ensures you always have the correct
working directory.

### Caching between runs

One limitation we haven't fully solved is caching. CI platforms have their own
caching mechanisms (GitHub Actions cache, GitLab CI cache), but these don't
integrate seamlessly with Docker layer caching. For now, we accept some
redundant work between runs. We're exploring solutions like mounting a
persistent cache directory, but haven't settled on a pattern we're happy with
yet. This is one of those features we're willing to sacrifice for portability.

### Matrix builds

Taskfile doesn't have native support for parallel matrix builds like GitHub
Actions does. We can work around this with shell constructs:

```yaml
build-matrix:
  desc: Build for multiple configurations
  cmds:
    - |
      echo "debug release production" | tr ' ' '\n' | \
      xargs -P 3 -I {} sh -c 'task build CONFIG={}'
```

But honestly, for complex matrices, we've decided it's acceptable to use the CI
platform's matrix feature and just call Taskfile from each matrix job:

```yaml
# GitHub Actions
strategy:
  matrix:
    config: [debug, release]
    platform: [arm, x86]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: arduino/setup-task@v1
      - run: task build CONFIG=${{ matrix.config }} PLATFORM=${{ matrix.platform }}
```

This is a reasonable compromise - the orchestration uses platform features, but
the build logic stays portable.

## What we learned

Based on our evaluation, Taskfile + Docker seems to hit a sweet spot for our
needs. It's more structured than raw shell scripts, has better cross-platform
support than Make, and is far simpler than Dagger or Earthly. Whether it holds
up in practice remains to be seen - we plan to adopt it more widely and see how
it works for us over time.

## But aren't we just depending on Task and Docker now?

This is a fair question. After all this talk about avoiding dependencies on
platforms that might change or disappear, aren't we just creating a new
dependency on Task and Docker?

We thought about this carefully, and we believe the risk profile is different.

**On Docker**: We're not really locked into Docker specifically. What we depend
on is the ability to run [OCI][oci]-compatible containers. If Docker disappeared
tomorrow, we could switch to [Podman][podman], [containerd][containerd], or any
other container runtime with minimal changes - mostly just replacing
`docker run` with `podman run` in our `_run` task. The container images
themselves are built using standard Dockerfiles and stored in standard
registries. There's no proprietary format or vendor-specific feature we depend
on. The OCI container standard is mature and widely adopted - it's not going
anywhere.

[oci]: https://opencontainers.org/
[podman]: https://podman.io/
[containerd]: https://containerd.io/

**On Taskfile**: Task is a relatively small, focused project. It's written in
Go, compiles to a single binary, and is essentially feature-complete for what we
need. The Taskfile format is simple YAML - there's no complex DSL or proprietary
syntax. If Task were abandoned, we have a few options:

- The existing binary would continue to work indefinitely
- We could fork and maintain it ourselves (it's a manageable codebase)
- We could migrate to Make with relatively little effort - the task
  definitions would need rewriting, but the Docker commands and scripts they
  invoke would stay the same
- We could write a simple wrapper that parses the YAML and runs the commands

The key difference from CI platform lock-in is that our actual build logic -
the Docker images, the scripts, the compilation commands - lives outside of
Task. Task is just the glue that invokes `docker run` with the right arguments.
If we had to replace it, we'd be rewriting task definitions, not build logic.

Compare this to migrating from GitHub Actions to GitLab CI, where the workflow
syntax, available actions, environment variables, secret handling, and artifact
management all change. That's a much deeper dependency.

So yes, we depend on Task and Docker, but at least in theory, they're
dependencies we can escape from without rewriting our core build infrastructure.
That's the level of portability we were aiming for. Whether this holds up in
practice is something we'll learn as we use this approach on more projects.

## What's next

Our research has led us to Taskfile + Docker as the most promising approach, but
we haven't battle-tested it yet. The next step is to adopt it more widely across
our projects and see how it holds up in practice. There are also a few things we
want to explore:

- **Validate the approach at scale**: We need to try this on more projects and
  see if the patterns hold up, or if we run into limitations we haven't
  anticipated
- **Better caching**: We want to find a clean pattern for persisting build
  caches across CI runs without coupling too tightly to any platform's caching
  system
- **Secret handling**: Currently, we pass secrets as environment variables, but
  we'd like a more structured approach
- **More reusable patterns**: We're building a library of common task
  definitions (running linters, generating documentation, publishing artifacts)
  that we can include across projects

We may find that Taskfile + Docker isn't the right fit after all, or that we
need to adjust our approach. If so, we'll share what we learn.

## Summary

After years of reacting to CI platform changes - pricing shifts, policy updates,
platforms rising and falling - we decided to research approaches that could give
us more independence. The key insight from this exercise is simple: treat CI
systems as thin orchestration layers, and keep your actual build logic in
portable, containerized tasks.

Based on our evaluation, Taskfile + Docker appears to be the best match for our
needs. It's not perfect - it lacks some conveniences of dedicated CI tools, and
we've accepted that trade-off. The promise is that we can run `task build` on
any developer's laptop and get the same result as in GitHub Actions, Gitea
Actions, Woodpecker, or whatever platform we end up using next. Whether that
promise holds up in practice is something we'll find out as we adopt it more
widely.

If you're tired of rewriting pipelines every time the CI landscape shifts - or
every time a provider changes their pricing model - it might be worth exploring
a similar approach. Start with a simple Taskfile that wraps your existing build
commands in Docker containers, and see if it works for your workflow. We'll
report back on how it goes for us.

Unlock the full potential of your hardware and secure your firmware with the
experts at 3mdeb! If you're looking to boost your product's performance and
protect it from potential security threats, our team is here to help. [Schedule
a call with
us](https://cloud.3mdeb.com/index.php/apps/calendar/appointment/n7T65toSaD9t) or
drop us an email at `contact<at>3mdeb<dot>com` to start unlocking the hidden
benefits of your hardware. And if you want to stay up-to-date on all things
firmware security and optimization, be sure to sign up for our newsletter:

{{< subscribe_form
  "3160b3cf-f539-43cf-9be7-46d481358202" "Subscribe to 3mdeb Newsletter" >}}
