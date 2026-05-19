# diploma-gitops

GitOps source of truth for the diploma project. ArgoCD watches this repository and reconciles desired state to the AKS cluster.

## Structure

```
.
├── apps/                       ArgoCD Application manifests (one per service per environment)
├── bootstrap/                  Root Application (app-of-apps) and AppProjects
├── helm-charts/                Custom Helm charts for each microservice
└── environments/               Per-environment Helm value overrides (dev, test, prod)
```

## Repository pattern

Trunk-based, single `main` branch, directory-per-environment. Promotion happens via pull requests that copy image tags between `environments/dev/`, `environments/test/`, and `environments/prod/`.

This follows the Codefresh/ArgoCD recommendation against permanent per-environment branches.

## Image flow

1. `diplomna-rabota` monorepo CI builds, signs (Cosign), and publishes images to `ghcr.io/svetlioo/<service>` with SBOM and SLSA provenance attached as OCI artifacts.
2. ArgoCD Image Updater watches GHCR for new tags matching the SemVer + build pattern and writes the new tag to `environments/dev/values-*.yaml` on `main`.
3. ArgoCD reconciles the `dev` namespace automatically. Promotion to `test` and `prod` is manual (pull request).
4. Kyverno verifies the Cosign signature and SLSA provenance at admission. Pods with unsigned or unverifiable images are rejected.

## Environments

| Namespace | Sync mode  | Source                       | Purpose                            |
|-----------|------------|------------------------------|------------------------------------|
| `dev`     | automatic  | latest signed image from CI  | Continuous integration target      |
| `test`    | manual PR  | promoted from `dev`          | DAST (ZAP) and integration testing |
| `prod`    | manual PR  | promoted from `test`         | Production-equivalent              |
