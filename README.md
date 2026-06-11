# diplomna-rabota-gitops

Желано състояние на клъстера. ArgoCD следи това хранилище и синхронизира средите
`dev` / `test` / `prod` в AKS. Промяна тук означава промяна в клъстера.

## Структура

```
.
├── apps/            ArgoCD Application манифести (по един на услуга на среда) + kyverno-policies
├── bootstrap/       Root Application (app-of-apps) + AppProject
├── helm-charts/     Helm chart за всяка услуга (bank-service, fraud-detection, frontend)
├── environments/    Values по среда (dev/test/prod): таг и digest на образа, реплики, ресурси
└── policies/        Kyverno ClusterPolicy (verify-image-signatures + restrict-image-registries)
```

## Поток на образите

1. CI в `diplomna-rabota` изгражда, подписва (Cosign keyless) и публикува образа в
   `ghcr.io/svetlioo/<услуга>` заедно със SBOM и SLSA provenance.
2. **dev е автоматично**: CI отваря и слива pull request тук, който обновява
   `environments/dev/values-<услуга>.yaml` с новия таг и digest. ArgoCD
   синхронизира dev. Внедрява се само променената услуга.
3. **test и prod са ръчни** през Promote workflow (по-долу).
4. При допускане Kyverno налага двете политики: `verify-image-signatures` (Cosign
   подпис + SLSA provenance + CycloneDX SBOM attestation) и
   `restrict-image-registries` (само `ghcr.io/svetlioo/*`). Неподписан, подменен
   или чужд образ се отказва.

## Придвижване между среди (Promote workflow)

`.github/workflows/promote.yml`, пуска се ръчно от **Actions → Promote image →
Run workflow**: избираш услуга (една или повече) и посока (`dev-to-test` или
`test-to-prod`). Workflow-ът копира таг и digest от изходната среда в целевата и
отваря pull request, който човек преглежда и слива. `prod` винаги взима
test-валидирания образ. Придвижва се същият подписан артефакт, без повторно
изграждане.

Workflow-ът отваря PR-а с `GITOPS_TOKEN`, защото PR, отворен със стандартния
`GITHUB_TOKEN`, не тригерира checks и засяда (виж Настройка по-долу).

## Среди

| Namespace | Обновяване | Източник |
|---|---|---|
| `dev` | автоматично от CI | последен подписан образ |
| `test` | ръчен PR (Promote) | придвижен от `dev` |
| `prod` | ръчен PR (Promote) | придвижен от `test` |

Един `main` branch, директория на среда, придвижване само през pull request.

## Настройка на хранилището (еднократно)

- Първоначално зареждане в клъстера (след изградена инфраструктура от
  `diplomna-rabota-infra`): `kubectl apply -f bootstrap/`. Root приложението
  създава останалите по модела app-of-apps.
- Settings → Actions → General: включи "Allow GitHub Actions to create and
  approve pull requests" (за Promote workflow-а).
- Secret `GITOPS_TOKEN` (fine-grained PAT с Contents и Pull requests write върху
  това хранилище): ползва се от Promote workflow-а и от CI на `diplomna-rabota`
  за автоматичния dev pull request.
- Branch ruleset на `main`: изисква pull request и преминали проверки (Gitleaks,
  Trivy config); забранен директен push.
- Gitleaks hook за тайни (еднократно след клониране): `pre-commit install`

## Лиценз

[Apache License 2.0](LICENSE)
