$files = @(
    "resources-spa\json\mysteries.json",
    "resources-ita\json\mysteries.json",
    "resources-por\json\mysteries.json",
    "resources-deu\json\mysteries.json",
    "resources-pol\json\mysteries.json",
    "resources-vie\json\mysteries.json"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw -Encoding UTF8
        # Force writing as UTF8 with BOM
        [System.IO.File]::WriteAllText((Resolve-Path $file).Path, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Fixed encoding for $file"
    } else {
        Write-Host "File not found: $file"
    }
}
