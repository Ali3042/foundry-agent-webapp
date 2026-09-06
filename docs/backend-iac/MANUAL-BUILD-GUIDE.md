# Manual build guide: recreating the process yourself

## Overview

There is no true `terraform import` equivalent required for ARM/Bicep. Azure Resource Manager is declarative: deploying a resource with the same resource ID updates/adopts it. The risk is that an incomplete template can still change existing settings. The manual process is therefore a **reconciliation exercise**, not a direct import command.

## Step 1 — inventory the estate

```powershell
az resource list `
  --resource-group ShareCloud `
  --query "[].{Name:name,Type:type,Location:location}" `
  -o table
```

Record child resources separately because a general resource list may not expose every child/control-plane object.

## Step 2 — capture each live resource

For ordinary ARM resources:

```powershell
az resource show `
  --resource-group ShareCloud `
  --name sharecloud-ai-search `
  --resource-type Microsoft.Search/searchServices `
  -o json > search.json
```

For Foundry child resources:

```powershell
$base = "https://management.azure.com/subscriptions/<sub>/resourceGroups/ShareCloud/providers/Microsoft.CognitiveServices/accounts/sharecloud-foundry-instance"

az rest --method get --url "$base/projects/proj-default?api-version=2025-06-01" -o json > project.json
az rest --method get --url "$base/projects/proj-default/connections?api-version=2025-06-01" -o json > project-connections.json
az rest --method get --url "$base/capabilityHosts?api-version=2025-06-01" -o json > account-capability-hosts.json
az rest --method get --url "$base/projects/proj-default/capabilityHosts?api-version=2025-06-01" -o json > project-capability-hosts.json
```

Capture identities and RBAC separately:

```powershell
az role assignment list --assignee-object-id <principal-id> --all -o json
```

## Step 3 — mark fields as desired, generated or secret

For every JSON property, classify it:

| Class | Examples | IaC action |
|---|---|---|
| Desired input | SKU, network ACL, retention, model version | Declare |
| Generated output | `id`, `etag`, `provisioningState`, endpoint, principalId | Omit/output |
| Server-managed | internal IDs, status, agent blueprint | Omit |
| Secret | API key, connection credential | Secure parameter/Key Vault; never copy plaintext |
| Uncertain | undocumented discriminator or service-generated default | Gate and verify with what-if |

A spreadsheet works well for this. Use one row per property and an `IaC decision` column.

## Step 4 — choose resource API versions

Use Microsoft’s template reference, not the version returned by habit or copied from a random sample. Select the newest stable version that exposes the properties you need.

Example:

```bicep
resource search 'Microsoft.Search/searchServices@2025-05-01' = {
  name: 'sharecloud-ai-search'
  location: resourceGroup().location
  sku: {
    name: 'free'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    publicNetworkAccess: 'Enabled'
  }
}
```

## Step 5 — build resources in dependency order

Start with the VNet/subnet and monitoring. Then add storage/data services, Search, Foundry and Key Vault. Add project connections and role assignments last.

Do not copy resource order from an export; use symbolic references and module outputs.

## Step 6 — compile and lint locally

```powershell
az bicep lint --file ./infra/backend/main.bicep
az bicep build --file ./infra/backend/main.bicep
```

Compiler success only proves schema/syntax compatibility. It does not prove the template is safe to apply to the live estate.

## Step 7 — perform a read-only existence audit

```powershell
az deployment group create `
  --name sharecloud-backend-audit `
  --resource-group ShareCloud `
  --template-file ./infra/backend/audit-existing.bicep
```

Because every resource in that template is declared `existing`, it makes no resource changes but fails if a referenced object cannot be resolved.

## Step 8 — run what-if

```powershell
az deployment group what-if `
  --name sharecloud-backend-adoption `
  --resource-group ShareCloud `
  --template-file ./infra/backend/main.bicep `
  --parameters @./infra/backend/parameters/sharecloud.prod.json `
  --result-format FullResourcePayloads
```

Review:

- deletes: there should be none in incremental mode;
- replaces: generally unacceptable for live stateful services;
- modifications: verify each property;
- noisy read-only differences: confirm they are service-generated rather than desired drift.

Save the what-if output as project evidence.

## Step 9 — adopt one category at a time

A cautious manual sequence is:

1. networking and monitoring;
2. storage and Search;
3. Cosmos DB;
4. Foundry account/project/model;
5. Key Vault;
6. RBAC;
7. project connections;
8. capability hosts.

After each category, rerun what-if. The target is a progressively smaller/no-change plan.

## Step 10 — keep the resource plane separate from the data/control plane

Bicep naturally manages ARM resources. It should not automatically absorb every mutable application object.

For ShareCloud:

- Bicep: Azure resources, identities, networking, RBAC, Foundry project/model/connections;
- separate bootstrap/versioned scripts: RAI policy, agent v15 definition, Foundry IQ knowledge base and SharePoint source configuration;
- runtime deployment: frontend/backend container image and pinned agent version.

This separation keeps infrastructure replacement from accidentally recreating or deleting live knowledge and agent configuration.
