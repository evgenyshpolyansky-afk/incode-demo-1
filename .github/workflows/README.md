This folder contains GitHub Actions workflows.

- build-and-publish.yml: Builds the Docker image from `apps/` on push to `main`, tags it with a timestamp and short git SHA, pushes to ECR, and updates `apps/version.txt` with the image URI.
