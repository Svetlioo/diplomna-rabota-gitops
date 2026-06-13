# diplomna-rabota-gitops

Желано състояние на клъстера. ArgoCD следи това хранилище и синхронизира средите
`dev` / `test` / `prod` в AKS. Промяна тук означава промяна в клъстера.

## Структура

```
.
├── helm-charts/             Helm chart за всяка услуга
│   ├── bank-service/
│   ├── fraud-detection/
│   └── frontend/
├── apps/                    ArgoCD Application манифести (по услуга и среда)
├── bootstrap/               root app-of-apps и AppProject
├── policies/                Kyverno ClusterPolicy (подпис, регистри)
└── environments/            values по среда с таг, digest и реплики
```

## Поток на образите

1. CI в `diplomna-rabota` изгражда, подписва (Cosign keyless) и публикува образа в
   `ghcr.io/svetlioo/<услуга>` заедно със SBOM и SLSA provenance.
2. **dev е автоматично.** CI отваря и слива pull request тук, който обновява
   `environments/dev/values-<услуга>.yaml` с новия таг и digest. ArgoCD
   синхронизира dev. Внедрява се само променената услуга.
3. **test и prod са ръчни** през Promote workflow (по-долу).
4. При допускане Kyverno налага двете политики `verify-image-signatures` (Cosign
   подпис, SLSA provenance и CycloneDX SBOM attestation) и
   `restrict-image-registries` (само `ghcr.io/svetlioo/*`). Неподписан, подменен
   или чужд образ се отказва.

## Придвижване между среди (Promote workflow)

`.github/workflows/promote.yml` се пуска ръчно от **Actions → Promote image →
Run workflow**. Избираш услуга (една или повече) и посока (`dev-to-test` или
`test-to-prod`). Workflow-ът копира таг и digest от изходната среда в целевата и
отваря pull request, който човек преглежда и слива. `prod` винаги получава
образа, преминал валидация в `test`. Придвижва се същият подписан артефакт, без
повторно изграждане.

## Среди

| Namespace | Обновяване | Източник |
|---|---|---|
| `dev` | автоматично от CI | последен подписан образ |
| `test` | ръчен PR (Promote) | придвижен от `dev` |
| `prod` | ръчен PR (Promote) | придвижен от `test` |

Един `main` branch, директория на среда, придвижване само през pull request.

## Настройка на хранилището (еднократно)

- Първоначално зареждане в клъстера след изградена инфраструктура от
  `diplomna-rabota-infra` с `kubectl apply -f bootstrap/`; root приложението
  създава останалите по модела app-of-apps.
- От Settings → Actions → General се включва "Allow GitHub Actions to create and
  approve pull requests" (за Promote workflow).
- Secret `GITOPS_TOKEN` (fine-grained PAT с Contents и Pull requests write върху
  това хранилище) се ползва от Promote workflow и от CI на `diplomna-rabota` за
  автоматичния dev pull request.
- Branch ruleset на `main` изисква pull request и преминали проверки (Gitleaks,
  Trivy config) и забранява директен push.
- Gitleaks hook за тайни се активира еднократно след клониране с
  `pre-commit install`.

## Лиценз

[Apache License 2.0](LICENSE)
