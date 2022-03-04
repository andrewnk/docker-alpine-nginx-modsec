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

| Variables             | Description                                                                                                                                                                                                                                            | Default                                                                                                | Example                      |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ | ---------------------------- |
| CI_IMAGE_NAME         | The name of the source docker image that should be referenced when tagging and pushing                                                                                                                                                                 | ${CI_PROJECT_ID}-${CI_PIPELINE_ID}                                                                     |                              |
| DOCKER_IMAGE_NAME     | Adding this variable allows you the ability to name the image being pushed to the registry (e.g. `registry.example.com/mynamespace/myproject/DOCKER_IMAGE_NAME:latest`); this is useful when building and pushing different images to the same project |                                                                                                        | DOCKER_IMAGE_NAME: "nginx"   |
| DOCKER_TARGET         | This will append a hyphen followed by the value of DOCKER_TARGET (-DOCKER_TARGET) to the docker image tag; this is useful when creating multistage builds in a single MR                                                                               |                                                                                                        | DOCKER_TARGET: "development" |
| IMAGE_TAGS            | A list that will be used to tag the docker image and then pushed to the registry                                                                                                                                                                       | "${CI_COMMIT_REF_SLUG} ${CI_COMMIT_SHA} ${CI_COMMIT_SHORT_SHA} ${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}" |                              |
| TAG_IMAGE_WITH_TARGET | Whether or not append the target name to the image tag when pushing to the registry                                                                                                                                                                    | true                                                                                                   |                              |


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

| Variables             | Description                                                                                                                                                              | Default                                                                                                | Example                      |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ | ---------------------------- |
| CI_IMAGE_NAME         | The name of the source docker image that should be referenced when tagging and pushing                                                                                   | ${CI_PROJECT_ID}-${CI_PIPELINE_ID}                                                                     |                              |
| DOCKER_TARGET         | This will append a hyphen followed by the value of DOCKER_TARGET (-DOCKER_TARGET) to the docker image tag; this is useful when creating multistage builds in a single MR |                                                                                                        | DOCKER_TARGET: "development" |
| IMAGE_TAGS            | A list that will be used to tag the docker image and then pushed to the registry                                                                                         | "${CI_COMMIT_REF_SLUG} ${CI_COMMIT_SHA} ${CI_COMMIT_SHORT_SHA} ${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}" |                              |
| TAG_IMAGE_WITH_TARGET | Whether or not append the target name to the image tag when pushing to the registry                                                                                      | true                                                                                                   |                              |

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
