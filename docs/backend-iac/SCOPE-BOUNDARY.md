# Scope boundary

## Managed by the new backend Bicep stack

- ShareCloud VNet/subnet;
- shared Log Analytics workspace;
- backend Application Insights;
- backend Storage account;
- Cosmos DB account;
- Key Vault;
- Azure AI Search service;
- Foundry account;
- Foundry project;
- GPT-5 mini model deployment;
- optionally, non-secret project connections after adoption.

## Managed by the existing frontend Bicep stack

- `sharecloud-frontend-rg`;
- Container Registry;
- Container Apps Environment;
- Container App;
- frontend user-assigned managed identity;
- frontend/backend App Insights components in the frontend RG;
- application runtime environment variables;
- Entra application reuse/generation logic.

## Kept outside this Bicep v1

### Agent and knowledge configuration

- ShareCloud-Bids agent v15;
- system instructions and structured input;
- RAI policy;
- Foundry IQ knowledge base;
- SharePoint remote sources.

These are versioned control/data-plane objects. They should be captured in a separate bootstrap package so infrastructure adoption cannot unexpectedly replace application intelligence or knowledge-source configuration.

### Platform-managed and external items

- Network Watcher;
- GoDaddy DNS records;
- the Entra tenant itself;
- GitHub repository settings and OIDC federated credential;
- custom-domain certificate in the frontend resource group.

### Sensitive connection material

The App Insights project connection uses an API key. Its credential is not available in the safe live-state snapshot and is therefore not invented or embedded. It remains an existing connection in the first adoption stage.
