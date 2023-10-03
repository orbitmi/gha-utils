# Release initialization

## Overview

GitHub composite action for initializing application release branch following 
the trunk-based development principles.

Mandatory inputs:
- **release_type (major, minor, patch)**
  
  For instance, if the latest released version is 1.2.3, controller actually resolves
  what is next version number based on the chosen type. Also, source commit is different for
  listed `release_type`:
    - PATCH: 1.2.3 -> 1.2.4; source = commit tagged as `1.2.3`
    - MINOR: 1.2.3 -> 1.3.0; source = trunk branch (latest commit)
    - MAJOR: 1.2.3 -> 2.0.0; source = trunk branch (latest commit)

Optional parameters:

- **docs_dir**
  
  Directory root where to place release notes. The default `docs` directory means release notes 
  will be placed in `docs/chglog/release-notes-1.2.3.md`.

- **config_dir**
  Directory root for all configurations necessary for this action. Currently, `git-chglog`
  is the only app that requires configuration. The default value `.` means the project root 
  is also a configuration root. This parameter is especially useful if you want to pull configuration 
  from different repository and utilize as a global settings in current repository. The example is below:

```
...
jobs:
  run:
    steps:
      - name: Checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - name: Checkout config
        uses: actions/checkout@v2
        with:
          repository: 'orbitmi/tbd-test'
          path: 'testcfg' 
          token: ${{ secrets.CI_PAT }}
      - name: Prepare App for Release
        id: artifact
        uses: orbitmi/gha-utils/actions/init-release@main
        with:
          release_type: ${{ github.event.inputs.release_type }}
          config_dir: 'testcfg'

```

## FAQ

1) How to replace `github-action[bot]` user with our internal bot

You can achieve that by setting `GIT_USER_NAME` and `GIT_USER_EMAIL` environment variables in this action 

Example:
```
...
      - name: Prepare App for Release
        id: artifact
        uses: orbitmi/gha-utils/actions/init-release@main
        env:
          GIT_USER_NAME: ci[bot]
          GIT_USER_EMAIL: ci-user@example.com
        with:
          release_type: ${{ github.event.inputs.release_type }}
...
```
