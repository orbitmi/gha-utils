# Utility

Composite action used for resolving repository and organization name.
This workflow is generating 8 oputputs:
    - org_name
    - repo_name
    - app_version
    - app_revision
    - app_release_type
    - container_repo
    - branch_ref
    - head_branch_ref

Example output:

Repository name: reponame
Organization name: orgname
App Version: alpha-53329f6
Revision: Production
Release type: Alpha (Debug)
Container repo: eu.gcr.io/reponame
Branch ref: refs/heads/main
Head Branch ref: 