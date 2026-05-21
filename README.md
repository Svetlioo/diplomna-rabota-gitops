# diplomna-rabota-gitops

Desired state на клъстера. **ArgoCD** следи това репо и реконсилира средите
`dev` / `test` / `prod` в AKS. Промени тук = промени в клъстера.

## Структура

```
.
├── apps/            ArgoCD Application манифести (по един на сервиз на среда) + kyverno-policies
├── bootstrap/       Root Application (app-of-apps) + AppProject
├── helm-charts/     Custom Helm charts за всеки сервиз (bank-service, fraud-detection)
├── environments/    Per-env Helm values (dev/test/prod) — пинат едновременно tag + digest
└── policies/        Kyverno ClusterPolicy (проверка на Cosign подписи)
```

## Поток на образите

1. CI в `diplomna-rabota` build-ва, подписва (Cosign keyless), публикува в
   `ghcr.io/svetlioo/<сервиз>` + SBOM + SLSA provenance.
2. **dev = автоматично** — CI отваря и **авто-merge-ва** PR тук, който обновява
   `environments/dev/values-<сервиз>.yaml` с новия `tag` + `digest`. ArgoCD синква dev.
   Деплойва се **само променения сервиз**; ако се променят два → два отделни PR-а.
3. **test / prod = ръчно** през Promote workflow (виж по-долу).
4. При admission **Kyverno** проверява Cosign подписа; неподписан или подменен образ
   се отказва.

## Промоция между среди — `Promote image` workflow

`.github/workflows/promote.yml` (`workflow_dispatch`). Пуска се от **Actions → Promote image → Run workflow**:

- **service:** `bank` / `fraud` / `both`
- **path:** `dev-to-test` или `test-to-prod`

Копира образа (`tag` + `digest`) от по-долната среда в по-горната и **отваря PR** —
**не го мърджва автоматично**. Човек преглежда и одобрява (separation of duties).
`prod` винаги взима **test-валидирания** образ, не директно от dev.

> Изисква в **Settings → Actions → General** да е включено
> „Allow GitHub Actions to create and approve pull requests".

## Среди

| Namespace | Sync | Източник | Цел |
|---|---|---|---|
| `dev` | автоматично | последен подписан образ от CI | непрекъсната интеграция |
| `test` | ръчен PR (Promote) | промотиран от `dev` | интеграционни тестове / DAST |
| `prod` | ръчен PR (Promote) | промотиран от `test` | продукционно-еквивалентна |

Trunk-based, един `main` branch, директория-на-среда. Промоцията е през PR-и, които
копират образа между `environments/dev|test|prod/` — без постоянни per-env branch-ове.

## Лиценз

[Apache License 2.0](LICENSE)
