# Progress log

## Completed

- Received current repository IaC archive.
- Received backend live-state snapshot archive.
- Verified both ZIPs and every expected file.
- Parsed all 11 snapshot JSON documents.
- Identified existing repo IaC as frontend-focused.
- Classified backend resources, dependencies and management boundaries.
- Normalised live state into writable desired-state properties.
- Selected stable Bicep API versions for each resource type.
- Created modular backend Bicep entry point.
- Preserved live networking, retention, SKU, identity and model settings.
- Added adoption gate for project connections.
- Excluded redacted App Insights API-key connection from recreation.
- Added read-only existence audit template.
- Added PR compile/lint and manual GitHub what-if/deploy workflow.
- Added repeatable state-capture script including capability hosts and RBAC.
- Added manual reproduction guide and adoption runbook.

## Not yet completed in Azure

- Bicep compilation using Azure CLI/Bicep.
- Resource-group what-if against the live `ShareCloud` estate.
- Capture of capability-host definitions.
- Capture/reconciliation of backend Foundry RBAC assignments.
- First incremental adoption deployment.
- Optional project-connection adoption.
- Separate versioned bootstrap for RAI policy, agent v15 and Foundry IQ configuration.

## Decision record

- Bicep retained rather than introducing Terraform.
- Backend and frontend stacks kept separate.
- Network Watcher left platform-managed.
- Project connection adoption disabled by default.
- No secret or missing role/capability-host state inferred.
