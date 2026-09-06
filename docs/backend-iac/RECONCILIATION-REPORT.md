# ShareCloud backend reconciliation report

## Inputs validated

| Input | Result |
|---|---|
| Current repository IaC ZIP | Valid; 17 files; no archive errors |
| Backend live-state snapshot ZIP | Valid; 11 JSON files; all parsed; no empty files |

## Live resources mapped into Bicep

| Live resource | Bicep module | Adoption treatment |
|---|---|---|
| `sharecloud-vnet` | `networking.bicep` | Managed; address space, subnet and service endpoints preserved |
| `sharecloud-log-workspace` | `monitoring.bicep` | Managed; PerGB2018 and 30-day retention preserved |
| `sharecloud-app-insights` | `monitoring.bicep` | Managed; workspace-based, 90-day retention preserved |
| `sharecloudstorage` | `storage.bicep` | Managed; Standard_LRS, TLS 1.2, current network mode preserved |
| `sharecloud-cosmos-db` | `cosmos.bicep` | Managed; serverless, Session, continuous seven-day backup and ACLs preserved |
| `sharecloud-ai-search` | `search.bicep` | Managed; free SKU, semantic free, AAD/API-key auth and public access preserved |
| `sharecloud-foundry-instance` | `foundry.bicep` | Managed; AIServices/S0, system identity, network ACLs and project management preserved |
| `proj-default` | `foundry.bicep` | Managed; project system identity, display name and description preserved |
| `gpt-5-mini` deployment | `foundry.bicep` | Managed; model version, capacity and auto-upgrade policy preserved |
| `sharecloud-kv` | `key-vault.bicep` | Managed; RBAC, firewall and legacy access policy preserved initially |

## Project connections

The snapshot contained six project connections.

Five non-secret connections are represented in `project-connections.bicep`, but the module is disabled by default:

- Key Vault — `AccountManagedIdentity`;
- Search — `AAD`;
- Storage — `AAD`;
- Cosmos DB — `AAD`;
- Foundry IQ MCP knowledge base — `ProjectManagedIdentity`.

The App Insights connection is **not recreated** because the live connection uses `ApiKey` and the credential was correctly absent/redacted from the snapshot. The first adoption deployment leaves all existing project connections untouched.

The resource provider currently returns `AccountManagedIdentity` and `ProjectManagedIdentity` values even though the published 2025-06-01 Bicep discriminator list does not enumerate those values. The module uses `any()` around those two property objects and is therefore explicitly adoption-gated.

## Deliberately unmanaged in v1

| Object | Reason |
|---|---|
| Network Watcher | Regional/platform-managed supporting resource; not part of ShareCloud desired state |
| Foundry account capability host | Not captured; immutable/recreation-sensitive |
| Foundry project capability host | Not captured; immutable/recreation-sensitive |
| Foundry/backend RBAC set | Snapshot did not include role assignments; guessing would be unsafe |
| App Insights project-connection API key | Secret not present; should come from a secure bootstrap if managed later |
| RAI policy | Data/control-plane definition not captured in this snapshot |
| Agent v15 | Versioned application/control-plane artefact, not core ARM infrastructure |
| Foundry IQ knowledge base and SharePoint sources | Search/Foundry control/data plane; manage in separate bootstrap |
| Frontend resource group | Already managed by the existing root `infra/` Bicep stack |

## Drift-sensitive items requiring human review

### IP allow-lists

The parameter file preserves the current Foundry and Cosmos IP lists to reduce first-run drift. Some entries may be temporary administrator or Azure service addresses. They should be reviewed and rationalised after adoption rather than silently removed in the first deployment.

### Storage firewall mode

The storage account currently has `defaultAction: Allow` while also listing the VNet subnet. That subnet rule is therefore not a restrictive control. The template preserves the live state; hardening should be a separate change with connectivity testing.

### Foundry firewall mode

The Foundry account currently has `defaultAction: Allow`, so its IP/VNet rules do not currently create a deny-by-default perimeter. This is preserved rather than unexpectedly hardened during adoption.

### Key Vault mixed access model

The Key Vault has RBAC enabled and still contains a legacy access policy for the Foundry account identity. The template preserves that policy by default. After role assignments are captured and validated, set `preserveLegacyKeyVaultAccessPolicy=false` only as an explicit hardening change.

### Search local authentication

The Search service currently allows both AAD and API-key authentication. `disableLocalAuth=false` is preserved. Moving to AAD-only authentication should be assessed separately.

### Model auto-upgrade

The model deployment uses `OnceNewDefaultVersionAvailable`, not `NoAutoUpgrade`. The template preserves this behaviour. A reproducibility decision should be made deliberately rather than changed during adoption.

## Expected first what-if behaviour

The target is no destructive change. Some modification noise may still appear due to:

- casing normalisation (`France Central` vs `francecentral`);
- properties returned by GET but omitted from PUT;
- provider-default values;
- system/hidden tags;
- API-version normalisation.

Do not deploy until each modification is understood. Update the Bicep or parameter file to match desired state rather than accepting unexplained drift.
