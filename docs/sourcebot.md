# Sourcebot - Self-Hosted Code Intelligence Platform

Sourcebot is a self-hosted tool that helps you understand your codebase. It provides powerful code search, AI-powered code analysis, and navigation capabilities across all your repositories and branches, regardless of where they're hosted.

## Overview

Sourcebot offers two main capabilities:
- **Code Search**: Search and navigate across all your repos and branches, no matter where they're hosted
- **Ask Sourcebot**: Ask questions about your codebase and have Sourcebot provide detailed answers grounded with inline citations

## Key Features

### Ask Sourcebot
Ask Sourcebot gives you the ability to ask complex questions about your codebase in natural language. It uses Sourcebot's existing code search and navigation tools to allow reasoning models to search your code, follow code nav references, and provide an answer that's rich with inline citations and navigable code snippets.

**Key benefits:**
- **Bring your own model**: Configure to any language model you'd like
- **Inline citations**: Every answer Sourcebot provides is grounded with inline citations directly into your codebase
- **Multi-repo**: Ask questions about any repository you have indexed on Sourcebot

### Code Search
Search across all your repos/branches across any code host platform. Blazingly fast, and supports regular expressions, repo/language search filters, boolean logic, and more.

**Key benefits:**
- **Regex support**: Use regular expressions to find code with precision
- **Query language**: Scope searches to specific files, repos, languages, symbol definitions and more using a rich query language
- **Branch search**: Specify a list of branches to search across
- **Fast & scalable**: Sourcebot uses trigram indexing, allowing it to scale to massive codebases
- **Syntax highlighting**: Syntax highlighting support for over 100+ languages
- **Multi-repository**: Search across all of your repositories in a single search
- **Search suggestions**: Get search suggestions as you craft your query
- **Filter panel**: Filter results by repository or by language

### Code Navigation
Code navigation helps you jump between symbol definitions and references quickly when browsing source code in Sourcebot.

**Key benefits:**
- **Hover popover**: Hovering over a symbol reveals the symbol's definition signature in a inline preview
- **Go to definition**: Navigate to a symbol's definition(s)
- **Find references**: Get all references to a symbol
- **Cross-repository**: Sourcebot can resolve references and definitions across repositories

### Cross Code-Host Support
Connect your code from multiple code-host platforms and search across all of them from a single interface.

**Supported platforms:**
- GitHub
- GitLab
- BitBucket
- Gitea
- Gerrit
- Other Git Hosts
- Local Git Repos

**Key benefits:**
- **Auto re-syncing**: Sourcebot will periodically sync with code hosts to pull the latest changes
- **Flexible configuration**: Sourcebot uses an expressive JSON schema config format to specify exactly what repositories to index (and what not to index)
- **Parallel indexing**: Repositories are indexed in parallel

### Authentication
Sourcebot comes with built-in support for authentication via email/password, email codes, and various SSO providers.

**Key benefits:**
- **Configurable auth providers**: Configure the auth providers that are available to your team
- **SSO**: Support for various SSO providers
- **_(coming soon)_ RBAC**: Role-based access control for managing user permissions
- **_(coming soon)_ Code host permission syncing**: Sync permissions from GitHub, Gitlab, etc. to Sourcebot
- **_(coming soon)_ Audit logs**: Audit logs for all actions performed on Sourcebot, such as user login, search, etc.

### Self-Hosted
Sourcebot is designed to be easily self-hosted, allowing you to deploy it onto your own infrastructure, keeping your code private and secure.

**Key benefits:**
- **Easy deployment**: Sourcebot is shipped as a single docker container that can be deployed to a k8s cluster, a VM, or any other platform that supports docker
- **Secure**: Your code **never** leaves your infrastructure
- **No-vendor lock-in**: Avoid dependency on a third-party SaaS provider; you can modify, extend, or migrate your deployment as needed

## Why Sourcebot?

- **Full-featured search**: Fast indexed-based search with regex support, filters, branch search, boolean logic, and more
- **Self-hosted**: Deploy it in minutes using our official docker container. All of your data stays on your machine
- **Modern design**: Light/Dark mode, vim keybindings, keyboard shortcuts, syntax highlighting, etc
- **Scalable**: Scales to millions of lines of code
- **Open-source**: Core features are MIT licensed

## Architecture

Sourcebot is shipped as a single docker container that runs a collection of services using supervisord. Sourcebot consists of the following components:

- **Web Server**: main Next.js web application serving the Sourcebot UI
- **Backend Worker**: Node.js process that incrementally syncs with code hosts (e.g., GitHub, GitLab etc.) and asynchronously indexes configured repositories
- **Zoekt**: the open-source, trigram indexing code search engine that powers Sourcebot under the hood
- **Postgres**: transactional database for storing business-logic data
- **Redis Job Queue**: fast in-memory store. Used with BullMQ for queuing asynchronous work
- **`.sourcebot/` cache**: file-system cache where persistent data is written

You can use managed Redis / Postgres services that run outside of the Sourcebot container by providing the `REDIS_URL` and `DATABASE_URL` environment variables, respectively.

## Deployment Guide

### Requirements

- Docker (use Docker Desktop on Mac or Windows)

### Deployment Steps

#### 1. Create a config.json

Create a `config.json` file that tells Sourcebot which repositories to sync and index:

```bash
touch config.json
```

Example configuration:

```json
{
    "$schema": "https://raw.githubusercontent.com/sourcebot-dev/sourcebot/main/schemas/v3/index.json",
    "connections": {
        // comments are supported
        "starter-connection": {
            "type": "github",
            "repos": [
                "sourcebot-dev/sourcebot"
            ]
        }
    }
}
```

This config creates a single GitHub connection named `starter-connection` that specifies Sourcebot as a repo to sync.

#### 2. Launch your instance

If you're deploying Sourcebot behind a domain, you must set the `AUTH_URL` environment variable.

In the same directory as `config.json`, run the following command to start your instance:

```bash
docker run \
    -p 3000:3000 \
    --pull=always \
    --rm \
    -v $(pwd):/data \
    -e CONFIG_PATH=/data/config.json \
    --name sourcebot \
    ghcr.io/sourcebot-dev/sourcebot:latest
```

**This command:**
- pulls the latest version of the `sourcebot` docker image
- mounts the working directory to `/data` in the container to allow Sourcebot to persist data across restarts, and to access the `config.json`. In your local directory, you should see a `.sourcebot` folder created that contains all persistent data
- runs any pending database migrations
- starts up all services, including the webserver exposed on port 3000
- reads `config.json` and starts syncing

#### 3. Complete onboarding

Navigate to `http://localhost:3000` and complete the onboarding flow.

#### 4. Done

You're all set! If you'd like to setup Ask Sourcebot, configure a language model provider.

## Scalability

One of our design philosophies for Sourcebot is to keep our infrastructure radically simple while balancing scalability concerns. Depending on the number of repositories you have indexed and the instance you are running Sourcebot on, you may experience slow search times or other performance degradations. Our recommendation is to vertically scale your instance by increasing the number of CPU cores and memory. Sourcebot does not support horizontal scaling at this time, but it is on our roadmap.

## License and Pricing

Sourcebot's core features are available under an MIT license without any limits. Some additional features such as SSO and code navigation require a license key.

## Telemetry

By default, Sourcebot collects anonymized usage data through PostHog to help us improve the performance and reliability of our tool. We don't collect or transmit any information related to your codebase. In addition, all events are sanitized to ensure that no sensitive details (ex. ip address, query info) leave your machine.

If you'd like to disable all telemetry, you can do so by setting the environment variable `SOURCEBOT_TELEMETRY_DISABLED` to `true`:

```bash
docker run \
  -e SOURCEBOT_TELEMETRY_DISABLED=true \
  /* additional args */ \
  ghcr.io/sourcebot-dev/sourcebot:latest
```

If you disabled telemetry correctly, you'll see the following log when starting Sourcebot:

```
Disabling telemetry since SOURCEBOT_TELEMETRY_DISABLED was set.
```

## Next Steps

- **Index your code**: Learn how to index your code using Sourcebot
- **Language models**: Learn how to configure language model providers to start using Ask Sourcebot
- **Authentication**: Learn more about how to setup SSO, email codes, and other authentication providers

## Troubleshooting

Hit an issue? Please let us know on [GitHub discussions](https://github.com/sourcebot-dev/sourcebot/discussions) or by emailing the Sourcebot team.

## Reference

- [Official Sourcebot Documentation](https://docs.sourcebot.dev/docs/overview)
- [Sourcebot GitHub Repository](https://github.com/sourcebot-dev/sourcebot)
- [Public Demo](https://demo.sourcebot.dev)
