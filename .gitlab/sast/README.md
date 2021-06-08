# CI Templates - SAST

This contains a series of SAST templates that can be included in your pipelines.

- [ShiftLeft](#shiftleft)
- [Trivy](#trivy)

---

## ShiftLeft

[ShiftLeft](https://slscan.io/en/latest/) is a general purpose SAST scanning tool that will scan the files in your project for vulnerabilities. After the scan is completed a report will be generated and available for download.

To use in your project first include the file in the top of your `.gitlab-ci.yml` file:

```
include: ".gitlab/sast/.shiftleft_container_scanning.yml"
```

Then add the job to the appropriate stage (e.g. in a stage titled `sast`):

```
shiftleft_container_scanning:
  stage: sast
  extends:
    - .shiftleft_container_scanning
  tags:
    - build
```

---

## Trivy

[Trivy](https://github.com/aquasecurity/trivy) is a general purpose SAST container scanning tool that will scan the files in your project for vulnerabilities. After the scan is completed a report will be generated and available for download.

To use in your project first include the file in the top of your `.gitlab-ci.yml` file:

```
include: ".gitlab/sast/.trivy_container_scanning.yml"
```

Then add the job to the appropriate stage (e.g. in a stage titled `sast`):

```
trivy_container_scanning:
  stage: sast
  extends:
    - .trivy_container_scanning
  tags:
    - build
```
