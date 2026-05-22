# unipept-devcontainers

This repository contains [Dev Container Features](https://containers.dev/implementors/features/) for Unipept development environments. Each feature can be referenced directly from a `devcontainer.json` file to set up the tools and data required by a specific Unipept service.

Features are published as GitHub Release assets on every push to `main`. The release version is read from the `version` field in each feature's `devcontainer-feature.json`.

---

## Features

### `unipept-index`

**Current version:** 1.1.0

Downloads and sets up a complete Unipept index environment, including the binary search index, the datastore files used by the Unipept API, and an OpenSearch instance pre-loaded with UniProt entries.

#### What it does

During the container build phase (`install.sh`), the feature:

1. Downloads the Unipept index archive (`index_SP_<date>.zip`) from the [`unipept/unipept-index`](https://github.com/unipept/unipept-index) GitHub releases.
2. Downloads the suffix array archive (`suffix_array.zip`) from the [`unipept/unipept-database`](https://github.com/unipept/unipept-database) GitHub releases.
3. Installs OpenSearch 2.x, writes a single-node configuration, and starts it temporarily.
4. Loads UniProt entries into OpenSearch using the initialization script from `unipept/unipept-database`.
5. Stops OpenSearch cleanly once data loading is complete.
6. Decompresses `.tsv.lz4` datastore files into `$UNIPEPT_INDEX_DATA/datastore/`.
7. Installs `/usr/local/bin/unipept-start-services.sh`, a startup script that consuming devcontainers use to bring OpenSearch up on each container start.

All data is stored under `/unipept-index-data`.

#### Options

| Option | Type | Default | Description |
|---|---|---|---|
| `version` | `string` | `latest` | Version of the index to download. Use `latest` for the most recent release, or a date in `YYYY-MM-DD` format to pin to a specific release. |

#### Usage

Add the feature to your `devcontainer.json` and call the startup script from `postStartCommand`:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "https://github.com/unipept/unipept-devcontainers/releases/download/v1.1.0/devcontainer-feature-unipept-index.tgz": {
      "version": "latest"
    }
  },
  "postStartCommand": "unipept-start-services.sh"
}
```

To pin to a specific index version:

```json
"features": {
  "https://github.com/unipept/unipept-devcontainers/releases/download/v1.1.0/devcontainer-feature-unipept-index.tgz": {
    "version": "2024-11-01"
  }
}
```

> **Why `postStartCommand`?**
> OpenSearch is stopped cleanly at the end of the build phase so that no stale lock files are left in the image. `postStartCommand` runs on every container start and brings OpenSearch back up. Without this line OpenSearch will not be running when the container opens.

#### What is available after setup

| Resource | Location |
|---|---|
| Binary index (`sa.bin`, `proteins.bin`, `mappings.bin`) | `/unipept-index-data/` |
| Decompressed datastore files | `/unipept-index-data/datastore/` |
| Installed index version | `/unipept-index-data/.VERSION` |
| OpenSearch HTTP endpoint | `http://localhost:9200` |
| OpenSearch logs | `/var/log/opensearch/startup.log` |

The environment variable `UNIPEPT_INDEX_DATA` is set to `/unipept-index-data` and can be used by the consuming application to locate the data directory.

---

## Releasing a new version

1. Update the `version` field in `unipept-index/devcontainer-feature.json`.
2. Push to `main`.

The `publish_features.yml` workflow creates a GitHub Release tagged `v<version>` and uploads the feature tarball as `devcontainer-feature-unipept-index.tgz`. Update the feature URL in any consuming `devcontainer.json` files to reference the new tag.

---

## Repository structure

```
unipept-devcontainers/
└── unipept-index/
    ├── devcontainer-feature.json   # Feature metadata and options
    └── install.sh                  # Build-phase installation script
```
