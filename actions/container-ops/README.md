# container-ops

Composite action used for bulding and pushing container images.
This workflow requires 2 mandatory parametes:
- push_image (Whether to push image to Docker Registry or not?)
- registry_login (Determine registry and try to login automatically (for ECR and self-hosted runners)) 

Currently registry_login is only supported for selfhosted runners on AWS.


container_ops script depends on app.config that is by default located in infra/ folder.

app.config has the following configuration:

CONTAINER_REPO=11111111.dkr.ecr.eu-west-1.amazonaws.com/something/{container_prefix}
CONTAINER_DIR="infra2/"

In this case if we have /{container_prefix} added it means that we have multiple services to build, for example:
api.Dockerfile
worker.Dockerfile
strongerworker.Dockerfile

In order for this composite action to work we have to follow this convention servicename.Dockerfile (servicename has to be lowercase otherwise in this case docker engine will not be able to build the image)

CONTAINER_DIR that points in infra2 is added in case if you want your service.Dockerfile in different folder if this value is not provided script will fallback to infra/ folder


or:

CONTAINER_REPO=11111111.dkr.ecr.eu-west-1.amazonaws.com/something
CONTAINER_DIR="infra3/"

In this case we are telling the scipt that there are no additional services to be built and it will default to Dockerfile in infra3/ folder