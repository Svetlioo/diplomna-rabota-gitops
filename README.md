# diplomna-rabota-gitops

Desired state на клъстера. **ArgoCD** следи това хранилище и реконсилира средите
`dev` / `test` / `prod` в AKS. Промени тук означават промени в клъстера.

## Структура

```
.
├── apps/            ArgoCD Application манифести (по един на сервиз на среда) + kyverno-policies
├── bootstrap/       Root Application (app-of-apps) + AppProject
├── helm-charts/     Custom Helm charts за всеки сервиз (bank-service, fraud-detection, frontend)
├── environments/    Per-env Helm values (dev/test/prod), пинат едновременно tag и digest
└── policies/        Kyverno ClusterPolicy-та (verify-image-signatures + restrict-image-registries)
```

## Поток на образите

1. CI в `diplomna-rabota` build-ва, подписва (Cosign keyless), публикува в
   `ghcr.io/svetlioo/<сервиз>` плюс SBOM и SLSA provenance.
2. **dev е автоматично**: CI отваря и авто-слива PR тук, който обновява
   `environments/dev/values-<сервиз>.yaml` с новия `tag` и `digest`. ArgoCD синква dev.
   Внедрява се само промененият сервиз; ако се променят два, стават два отделни PR-а.
3. **test и prod са ръчни** през Promote workflow (виж по-долу).
4. При admission **Kyverno** налага две политики: `verify-image-signatures` (Cosign подпис
   плюс SLSA provenance плюс CycloneDX SBOM атестации) и `restrict-image-registries` (само
   `ghcr.io/svetlioo/*`). Неподписан, неатестиран, подменен или образ от чуждо registry се отказва.

## Придвижване между среди (`Promote image` workflow)

`.github/workflows/promote.yml` (`workflow_dispatch`). Пуска се от **Actions → Promote image → Run workflow**:

- **bank / fraud / frontend:** чекбокс на услуга, отмяташ една или повече.
- **path:** `dev-to-test` или `test-to-prod`

Копира образите (`tag` и `digest`) на избраните услуги от по-долната среда в по-горната и
отваря един PR, без да го слива автоматично. Човек преглежда и одобрява (separation of
duties). `prod` винаги взима test-валидирания образ, не директно от dev.

> Изисква: (1) в **Settings → Actions → General** включено „Allow GitHub Actions to create and
> approve pull requests"; (2) secret **`GITOPS_TOKEN`** (fine-grained PAT) в това хранилище.
> Workflow-ът отваря PR-а с него, за да тръгнат required checks. PR, отворен с `GITHUB_TOKEN`,
> не тригерира workflow-и, така checks-овете никога не започват и PR-ът засяда.

## Среди

| Namespace | Sync | Източник | Цел |
|---|---|---|---|
| `dev` | автоматично | последен подписан образ от CI | непрекъсната интеграция |
| `test` | ръчен PR (Promote) | придвижен от `dev` | интеграционни тестове |
| `prod` | ръчен PR (Promote) | придвижен от `test` | продукционно-еквивалентна |

Trunk-based, един `main` branch, директория на среда. Придвижването е през PR-и, които
копират образа между `environments/dev|test|prod/`, без постоянни per-env branch-ове.

## Лиценз

[Apache License 2.0](LICENSE)
