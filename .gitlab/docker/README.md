# CI Templates - Docker

This repo contains a series of templates that can be included in your pipelines.

- [Build Docker Image](#build-docker-image)
- [Push Docker Image](#push-docker-image)
- [Remove Docker Image](#remove-docker-image)
- [Remove Docker Image From Registry](#remove-docker-image-from-registry)

---

## Build Docker Image

This job will build a docker image that can be be used in later stages. Any pipeline that includes a build job should always end with a job to [remove the image](#remove-docker-image).

To use in your project first include the file in the top of your `.gitlab-ci.yml` file:

```
include: ".gitlab/docker/.build_docker_image.yml"
```

Then add the job to the appropriate stage (e.g. in a stage titled `.pre`):

```
build_image:
  stage: .pre
  extends:
    - .build_docker_image
  tags:
    - build
```

| Variables            | Description                                                         | Default    |
| -------------------- | ------------------------------------------------------------------- | ---------- |
| DOCKER_BUILD_CONTEXT | Docker build context                                                | .          |
| DOCKERFILE_FILENAME  | The name of the Dockerfile                                          | Dockerfile |
| DOCKERFILE_PATH      | The relative path where the Dockerfile is located - must end in `/` | ./         |

---

## Push Docker Image

This job will tag the image with four tags, `CI_COMMIT_SHA`, `CI_COMMIT_SHORT_SHA`, `CI_COMMIT_BRANCH`, `CI_COMMIT_TAG` - provided they exist, and push the tagged images to the registry.

To use in your project first include the file in the top of your `.gitlab-ci.yml` file:

```
include: ".gitlab/docker/.push_docker_image.yml"
```

Then add the job to the appropriate stage (e.g. in a stage titled `push`):

```
push_image_to_registry:
  stage: push
  extends:
    - .push_docker_image
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH =~ /(?:dev|staging)/
  tags:
    - build
```

---

## Remove Docker Image

This job will remove the image that was built using the [build docker image job](#build-docker-image) and should often occur in the `.post` stage after testing and deployment has completed.

To use in your project first include the file in the top of your `.gitlab-ci.yml` file:

```
include: ".gitlab/docker/.remove_docker_image.yml"
```

Then add the job to the appropriate stage (e.g. in a stage titled `.post`):

```
remove_image:
  stage: .post
  extends:
    - .remove_docker_image
  when:
    always
  tags:
    - build
```

---

## Remove Docker Image From Registry

This job will remove an image from the registry using [genuinetools/reg](https://github.com/genuinetools/reg). It should primarily be used to delete a temporary image that has been created/pushed/used for testing.

To use in your project first include the file in the top of your `.gitlab-ci.yml` file:

```
include: ".remove_docker_image_from_registry.yml"
```

Then add the job to the appropriate stage (e.g. in a stage titled `remove-tmp-image`):

```
remove_image:
  stage: remove-tmp-image
  extends:
    - .remove_docker_image_from_registry
  when:
    always
  tags:
    - build
```

| Variables   | Description                | Default                                                          |
| ----------- | -------------------------- | ---------------------------------------------------------------- |
| IMAGE_TAG   | The image tag to delete    | ${CI_PROJECT_PATH}:${CI_COMMIT_SHORT_SHA}-${CI_PIPELINE_ID}      |
| REG_SHA256  | sha256sum for verification | ade837fc5224acd8c34732bf54a94f579b47851cc6a7fd5899a98386b782e228 |
| REG_VERSION | The version of reg to use  | 0.16.1                                                           |
