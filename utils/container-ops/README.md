# container-ops

Composite action used for bulding and puching container images.
This workflow requires 3 mandatory parametes:
    - dockerfile (locaction of dockerfile)
    - push_image (Whether to push image to Docker Registry or not?)
    - registry_login (Determine registry and try to login automatically (for ECR and self-hosted runners))

