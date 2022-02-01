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
          repository: 'htec-infra/tbd-test'
          path: 'testcfg' 
          token: ${{ secrets.CI_PAT }}
      - name: Prepare App for Release
        id: artifact
        uses: htec-infra/gha-utils/actions/init-release@feature/init-release-update
        with:
          release_type: ${{ github.event.inputs.release_type }}
          config_dir: 'testcfg'

```
- **multi_release_branches** (EXPERIMENTAL)
  The current version of this action doesn't support multiple release branches (only one release/x.x.x at the time)
  because of potential conflicts in creating release version tags. The default values is set to `false`, 
  but that behavior can be changed with this parameter. We are working towards improvements to remove this restriction.
  Nevertheless, a final version of this action will prevent multiple branches of the same type.
