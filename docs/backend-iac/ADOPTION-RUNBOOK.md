# Adoption runbook

## Phase 0 — prepare a branch

```powershell
cd /home/alistair/foundry-agent-webapp
git checkout main
git pull origin main
git checkout -b feature/sharecloud-backend-iac
```

Install the kit using `scripts/install-to-repo.ps1 -Check`, then apply it.

## Phase 1 — compile and lint

```powershell
az bicep version
az bicep lint --file ./infra/backend/main.bicep
az bicep build --file ./infra/backend/main.bicep
az bicep lint --file ./infra/backend/audit-existing.bicep
az bicep build --file ./infra/backend/audit-existing.bicep
```

Resolve all compiler errors before proceeding. Warnings must be understood; do not suppress them merely for a clean screenshot.

## Phase 2 — existence audit

```powershell
az deployment group create `
  --name sharecloud-backend-existence-audit `
  --resource-group ShareCloud `
  --template-file ./infra/backend/audit-existing.bicep `
  -o table
```

This template contains only `existing` resources. It should not change the estate.

## Phase 3 — local what-if

```powershell
az deployment group what-if `
  --name sharecloud-backend-adoption `
  --resource-group ShareCloud `
  --template-file ./infra/backend/main.bicep `
  --parameters @./infra/backend/parameters/sharecloud.prod.json `
  --result-format FullResourcePayloads `
  | Tee-Object ./sharecloud-backend-what-if.txt
```

Stop on any delete, replacement, or unexplained security/network change.

## Phase 4 — capture missing Agent Service state

```powershell
& ./scripts/capture-backend-state.ps1
```

Review:

- `account-capability-hosts.json`;
- `project-capability-hosts.json`;
- Foundry account/project role assignments.

Do not add capability hosts to Bicep without these exact definitions. Capability hosts are replacement-sensitive.

## Phase 5 — commit and PR

```powershell
git diff --check
git status --short
git add infra/backend .github/workflows/sharecloud-backend-infrastructure.yml docs/backend-iac scripts/capture-backend-state.ps1
git commit -m "Add ShareCloud backend Bicep adoption stack"
git push -u origin feature/sharecloud-backend-iac
```

Open a PR. The workflow should compile/lint only; it should not sign into Azure on a PR.

## Phase 6 — GitHub what-if

After merge to `main`:

```text
Actions
→ ShareCloud Backend Infrastructure
→ Run workflow
→ Operation: what-if
```

Download and retain the what-if artefact. Compare it with the local result.

## Phase 7 — first deployment

Only when the plan is accepted:

```text
Actions
→ ShareCloud Backend Infrastructure
→ Run workflow
→ Operation: deploy
```

The job runs what-if again before the incremental deployment.

## Phase 8 — post-deployment verification

```powershell
az deployment group show `
  --resource-group ShareCloud `
  --name <workflow-deployment-name> `
  --query "properties.provisioningState" `
  -o tsv

az resource list `
  --resource-group ShareCloud `
  --query "[].{Name:name,Type:type,Location:location}" `
  -o table
```

Then run a ShareCloud application smoke test:

- sign in through `sharecloud.faedown.co.uk`;
- perform a Discovery query with citations;
- perform a Drafting query;
- confirm agent v15 remains pinned;
- confirm no unexpected RBAC/network change.

## Phase 9 — connections and hardening

Leave `manageProjectConnections=false` during initial adoption. Enable it only after:

1. core deployment returns a clean what-if;
2. the connection module compiles against the current provider;
3. the existing App Insights connection strategy is documented;
4. a rollback path exists.

Treat network hardening, AAD-only Search, Key Vault access-policy removal and model pinning as separate pull requests.
