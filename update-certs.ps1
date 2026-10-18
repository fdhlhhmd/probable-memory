# ============================================================
# SKM Interview Portfolio - Certificate Auto-Indexer Script
# Automatically scans the 'sijil/' folder, parses all PDF
# certificates, and updates 'sijil/data.js' & 'index.html'.
# ============================================================

$rootPath = $PSScriptRoot
if (-not $rootPath) { $rootPath = Get-Location }

$sijilDir = Join-Path $rootPath "sijil"
$dataFile = Join-Path $sijilDir "data.js"
$rootIndex = Join-Path $rootPath "index.html"

Write-Host "Scanning '$sijilDir' for PDF certificates..." -ForegroundColor Cyan

$allFiles = Get-ChildItem -Path $sijilDir -Recurse -Filter "*.pdf"
$certList = @()

foreach ($f in $allFiles) {
    $folder = if ($f.Directory.Name -eq 'sijil') { 
        if ($f.Name -match "award") { "award" }
        elseif ($f.Name -match "profesional|professional") { "professional" }
        else { "award" }
    } else { 
        $f.Directory.Name 
    }

    $relPath = if ($f.Directory.Name -eq 'sijil') { $f.Name } else { "$($f.Directory.Name)/$($f.Name)" }
    $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    
    # Extract issuer
    $issuer = "Other"
    if ($nameWithoutExt -match "^google") { $issuer = "Google" }
    elseif ($nameWithoutExt -match "^aws") { $issuer = "AWS" }
    elseif ($nameWithoutExt -match "^datacamp") { $issuer = "DataCamp" }
    elseif ($nameWithoutExt -match "^upsi") { $issuer = "UPSI" }
    elseif ($nameWithoutExt -match "^celcom") { $issuer = "Celcom" }
    elseif ($nameWithoutExt -match "^bernama") { $issuer = "Bernama" }
    elseif ($nameWithoutExt -match "^tarumt") { $issuer = "TAR UMT" }
    elseif ($nameWithoutExt -match "^usm") { $issuer = "USM" }
    elseif ($nameWithoutExt -match "^allied-view") { $issuer = "Allied View" }
    elseif ($nameWithoutExt -match "^kbs") { $issuer = "KBS" }
    elseif ($nameWithoutExt -match "^gaqm") { $issuer = "GAQM" }
    elseif ($nameWithoutExt -match "^gdg") { $issuer = "GDG" }
    elseif ($nameWithoutExt -match "^ga-") { $issuer = "General Assembly" }

    # Extract year
    $year = "2024"
    if ($nameWithoutExt -match "(202[0-9])") {
        $year = $matches[1]
    }
    
    # Human-readable title
    $cleanTitle = $nameWithoutExt -replace "^(upsi|google|aws|datacamp|celcom|bernama|tarumt|usm|allied-view|kbs|gaqm|gdg|ga)-", ""
    $cleanTitle = $cleanTitle -replace "(award|appreciation|completion|recognition|participation|profesional|professional)-cert-?", ""
    $cleanTitle = $cleanTitle -replace "-?202[0-9]$", ""
    $cleanTitle = ($cleanTitle -split "-" | ForEach-Object { 
        if ($_ -eq "ai") { "AI" }
        elseif ($_ -eq "ieriich") { "IERIICH" }
        elseif ($_ -eq "chatgpt") { "ChatGPT" }
        elseif ($_ -eq "dalle") { "DALL-E" }
        elseif ($_ -eq "bi") { "Power BI" }
        elseif ($_ -eq "blis") { "BLIS" }
        elseif ($_ -eq "github") { "GitHub" }
        elseif ($_ -eq "siri1") { "Siri 1" }
        elseif ($_ -eq "siri12") { "Siri 12" }
        elseif ($_ -eq "beginers") { "Beginners" }
        elseif ($_ -eq "devops") { "DevOps" }
        elseif ($_ -eq "kitahack") { "KitaHack" }
        elseif ($_ -eq "gdg") { "GDG" }
        elseif ($_ -eq "power" -and $nameWithoutExt -match "power-bi") { "" }
        else { (Get-Culture).TextInfo.ToTitleCase($_) }
    }) -join " "
    $cleanTitle = $cleanTitle.Replace("  ", " ").Trim()
    
    $category = $folder.Substring(0,1).ToUpper() + $folder.Substring(1)

    $certList += [PSCustomObject]@{
        filename = $f.Name
        path = $relPath
        folder = $folder
        category = $category
        title = $cleanTitle
        issuer = $issuer
        year = $year
        size = [math]::Round($f.Length / 1KB, 1).ToString() + " KB"
    }
}

# Write out sijil/data.js
$json = $certList | ConvertTo-Json -Depth 4
$jsContent = "// Auto-generated certificate dataset`n// Run update-certs.ps1 to regenerate anytime new files are added.`nwindow.CERTIFICATES_DATA = $json;`n"
[System.IO.File]::WriteAllText($dataFile, $jsContent, [System.Text.Encoding]::UTF8)

# Update root index.html count badge if present
if (Test-Path $rootIndex) {
    $indexHtml = [System.IO.File]::ReadAllText($rootIndex, [System.Text.Encoding]::UTF8)
    $updatedHtml = [regex]::Replace($indexHtml, '\d+\s+Certificates', "$($certList.Count) Certificates")
    [System.IO.File]::WriteAllText($rootIndex, $updatedHtml, [System.Text.Encoding]::UTF8)
}

Write-Host "`nSUCCESS: Indexed $($certList.Count) certificates into '$dataFile'!" -ForegroundColor Green
Write-Host "Summary by category:" -ForegroundColor Yellow
$certList | Group-Object Folder | Select-Object @{Name="Category"; Expression={$_.Name}}, Count | Format-Table -AutoSize
Write-Host "Summary by issuer:" -ForegroundColor Yellow
$certList | Group-Object Issuer | Select-Object @{Name="Issuer"; Expression={$_.Name}}, Count | Format-Table -AutoSize
