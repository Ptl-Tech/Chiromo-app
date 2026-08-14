# ===================================================================
# Chiromo Hospital Database Export Script
# Exports each table as a separate JSON file into /database_export/
# ===================================================================

# -- Configuration --
$SUPABASE_URL = "https://micgxvckwdptihzbzmsr.supabase.co"

# Using anon key (limited by RLS - some tables may return empty)
# For FULL export, replace with your service_role key from:
#   https://supabase.com/dashboard/project/micgxvckwdptihzbzmsr/settings/api
$SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1pY2d4dmNrd2RwdGloemJ6bXNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5MjU2NTMsImV4cCI6MjA5OTUwMTY1M30.3la1fvzN75MSBvNMPdpVuBev3jho1j_cFUFq48xoEJ4"

# -- All Tables in Chiromo Database --
$tables = @(
    "profiles",
    "branches",
    "doctors",
    "appointments",
    "queues",
    "invoices",
    "cbt_exercises",
    "health_metrics",
    "departments",
    "services",
    "rooms",
    "doctor_schedules",
    "time_slots",
    "medical_records",
    "diagnoses",
    "prescriptions",
    "insurance_providers",
    "corporate_accounts",
    "insurance_claims",
    "payments",
    "notifications",
    "audit_logs",
    "chat_messages",
    "emergency_contacts",
    "safety_plans",
    "emergency_hotlines",
    "patient_chats",
    "patient_messages",
    "doctor_reviews"
)

# -- Create output directory --
$outputDir = Join-Path $PSScriptRoot "database_export"
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
Write-Host ""
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "  Chiromo Database Export - $timestamp" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""

# -- Headers --
$headers = @{
    "apikey"        = $SUPABASE_KEY
    "Authorization" = "Bearer $SUPABASE_KEY"
    "Accept"        = "application/json"
    "Prefer"        = "count=exact"
}

# -- Export each table --
$totalRows = 0
$successCount = 0
$failCount = 0
$summary = @()

foreach ($table in $tables) {
    $url = "$SUPABASE_URL/rest/v1/${table}?select=*"
    $outputFile = Join-Path $outputDir "$table.json"

    try {
        $response = Invoke-WebRequest -Uri $url -Headers $headers -Method Get -ErrorAction Stop
        $data = $response.Content

        # Get row count from content-range header or parse JSON
        $rowCount = 0
        $contentRange = $response.Headers["content-range"]
        if ($contentRange) {
            $parts = $contentRange -split "/"
            if ($parts.Length -gt 1 -and $parts[1] -ne "*") {
                $rowCount = [int]$parts[1]
            }
        }
        if ($rowCount -eq 0) {
            $parsed = $data | ConvertFrom-Json
            $rowCount = @($parsed).Count
        }

        # Pretty-print the JSON and save
        $parsed = $data | ConvertFrom-Json
        $prettyJson = $parsed | ConvertTo-Json -Depth 20
        $prettyJson | Out-File -FilePath $outputFile -Encoding utf8

        $totalRows += $rowCount
        $successCount++
        $summary += [PSCustomObject]@{
            Table  = $table
            Rows   = $rowCount
            Status = "OK"
            File   = "$table.json"
        }
        Write-Host "  [OK]   $table - $rowCount rows" -ForegroundColor Green
    }
    catch {
        $failCount++
        $errorMsg = $_.Exception.Message
        $summary += [PSCustomObject]@{
            Table  = $table
            Rows   = "-"
            Status = "FAILED"
            File   = "-"
        }
        Write-Host "  [FAIL] $table - $errorMsg" -ForegroundColor Red
    }
}

# -- Print Summary --
Write-Host ""
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "  EXPORT SUMMARY" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""
$summary | Format-Table -AutoSize
Write-Host ""
Write-Host "  Total tables exported: $successCount / $($tables.Count)" -ForegroundColor White
Write-Host "  Total rows exported:   $totalRows" -ForegroundColor White
if ($failCount -gt 0) {
    Write-Host "  Failed:                $failCount" -ForegroundColor Red
} else {
    Write-Host "  Failed:                $failCount" -ForegroundColor Green
}
Write-Host "  Output directory:      $outputDir" -ForegroundColor White
Write-Host ""

# -- Save summary as JSON --
$exportMeta = @{
    exported_at = $timestamp
    supabase_url = $SUPABASE_URL
    tables_exported = $successCount
    tables_failed = $failCount
    total_rows = $totalRows
    tables = $summary
}
$exportMeta | ConvertTo-Json -Depth 5 | Out-File -FilePath (Join-Path $outputDir "_export_summary.json") -Encoding utf8

Write-Host "  Summary saved to: _export_summary.json" -ForegroundColor Cyan
Write-Host ""
