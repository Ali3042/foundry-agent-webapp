[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = "78e6fea7-c1bc-4d10-87b1-22ad3590e3c3",

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = "ShareCloud",

    [Parameter(Mandatory = $false)]
    [string]$FoundryAccount = "sharecloud-foundry-instance",

    [Parameter(Mandatory = $false)]
    [string]$ProjectName = "proj-default",

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $HOME "sharecloud-iac-snapshot")
)

$ErrorActionPreference = "Stop"

function Invoke-AzJsonFile {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$OutputFile,
        [switch]$BestEffort
    )

    Write-Host "Capturing $(Split-Path $OutputFile -Leaf)..." -ForegroundColor Cyan
    $result = & az @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($BestEffort) {
            Write-Warning "Capture skipped: $($result -join [Environment]::NewLine)"
            return
        }
        throw "Azure CLI command failed while creating $OutputFile`n$($result -join [Environment]::NewLine)"
    }

    $text = $result -join [Environment]::NewLine
    $null = $text | ConvertFrom-Json
    Set-Content -Path $OutputFile -Value $text -Encoding utf8
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "Azure CLI was not found. Run this script in Azure Cloud Shell or another authenticated Azure CLI environment."
}

az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    throw "Unable to select subscription $SubscriptionId"
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$resources = @(
    @{ File = "foundry.json"; Name = $FoundryAccount; Type = "Microsoft.CognitiveServices/accounts" },
    @{ File = "search.json"; Name = "sharecloud-ai-search"; Type = "Microsoft.Search/searchServices" },
    @{ File = "cosmos.json"; Name = "sharecloud-cosmos-db"; Type = "Microsoft.DocumentDB/databaseAccounts" },
    @{ File = "keyvault.json"; Name = "sharecloud-kv"; Type = "Microsoft.KeyVault/vaults" },
    @{ File = "storage.json"; Name = "sharecloudstorage"; Type = "Microsoft.Storage/storageAccounts" },
    @{ File = "vnet.json"; Name = "sharecloud-vnet"; Type = "Microsoft.Network/virtualNetworks" },
    @{ File = "log-analytics.json"; Name = "sharecloud-log-workspace"; Type = "Microsoft.OperationalInsights/workspaces" },
    @{ File = "app-insights.json"; Name = "sharecloud-app-insights"; Type = "Microsoft.Insights/components" }
)

foreach ($resource in $resources) {
    Invoke-AzJsonFile -Arguments @(
        "resource", "show",
        "--resource-group", $ResourceGroup,
        "--name", $resource.Name,
        "--resource-type", $resource.Type,
        "--output", "json"
    ) -OutputFile (Join-Path $OutputDirectory $resource.File)
}

$accountBase = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.CognitiveServices/accounts/$FoundryAccount"
$projectBase = "$accountBase/projects/$ProjectName"

Invoke-AzJsonFile -Arguments @(
    "rest", "--method", "get",
    "--url", "$projectBase?api-version=2025-06-01",
    "--output", "json"
) -OutputFile (Join-Path $OutputDirectory "project.json")

Invoke-AzJsonFile -Arguments @(
    "cognitiveservices", "account", "deployment", "list",
    "--name", $FoundryAccount,
    "--resource-group", $ResourceGroup,
    "--output", "json"
) -OutputFile (Join-Path $OutputDirectory "model-deployments.json")

Invoke-AzJsonFile -Arguments @(
    "rest", "--method", "get",
    "--url", "$projectBase/connections?api-version=2025-06-01",
    "--output", "json"
) -OutputFile (Join-Path $OutputDirectory "project-connections.json")

# These objects are essential for a full greenfield Agent Service recreation, but
# are not always returned by general resource-list commands. Capture them explicitly.
Invoke-AzJsonFile -Arguments @(
    "rest", "--method", "get",
    "--url", "$accountBase/capabilityHosts?api-version=2025-06-01",
    "--output", "json"
) -OutputFile (Join-Path $OutputDirectory "account-capability-hosts.json") -BestEffort

Invoke-AzJsonFile -Arguments @(
    "rest", "--method", "get",
    "--url", "$projectBase/capabilityHosts?api-version=2025-06-01",
    "--output", "json"
) -OutputFile (Join-Path $OutputDirectory "project-capability-hosts.json") -BestEffort

Invoke-AzJsonFile -Arguments @(
    "resource", "list",
    "--resource-group", $ResourceGroup,
    "--output", "json"
) -OutputFile (Join-Path $OutputDirectory "resource-inventory.json")

$foundryJson = Get-Content (Join-Path $OutputDirectory "foundry.json") -Raw | ConvertFrom-Json
$projectJson = Get-Content (Join-Path $OutputDirectory "project.json") -Raw | ConvertFrom-Json

$principalCaptures = @(
    @{ File = "foundry-account-role-assignments.json"; PrincipalId = $foundryJson.identity.principalId },
    @{ File = "foundry-project-role-assignments.json"; PrincipalId = $projectJson.identity.principalId }
)

foreach ($capture in $principalCaptures) {
    if ($capture.PrincipalId) {
        Invoke-AzJsonFile -Arguments @(
            "role", "assignment", "list",
            "--assignee-object-id", $capture.PrincipalId,
            "--all",
            "--output", "json"
        ) -OutputFile (Join-Path $OutputDirectory $capture.File)
    }
}

$manifest = Get-ChildItem -Path $OutputDirectory -File |
    Sort-Object Name |
    ForEach-Object {
        [pscustomobject]@{
            Name = $_.Name
            Bytes = $_.Length
            Sha256 = (Get-FileHash -Algorithm SHA256 -Path $_.FullName).Hash
        }
    }

$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $OutputDirectory "manifest.json") -Encoding utf8

$zipPath = "$OutputDirectory.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}
Compress-Archive -Path (Join-Path $OutputDirectory "*") -DestinationPath $zipPath -Force

Write-Host "Snapshot complete: $zipPath" -ForegroundColor Green
Write-Host "The capture uses read-only GET/list operations and intentionally excludes account keys and bearer tokens." -ForegroundColor DarkGray
