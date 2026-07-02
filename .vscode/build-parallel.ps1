# Parallel LaTeX Build Script
Write-Host "=== Parallel LaTeX Build Script ===" -ForegroundColor Magenta

# Find all TeX files in main directory
$texFiles = Get-ChildItem -Path ".\main\*.tex"
Write-Host "Found $($texFiles.Count) TeX files to compile in parallel..." -ForegroundColor Cyan

# Start compilation
$processes = @()
foreach ($file in $texFiles) {
    Write-Host "Compiling $($file.Name) with tectonic..." -ForegroundColor Yellow
    $process = Start-Process -FilePath "tectonic" -ArgumentList "-o", ".", "-Z", "search-path=.", "-Z", "search-path=sty", $file.FullName -PassThru -NoNewWindow -Wait:$false
    $processes += @{Process=$process; FileName=$file.Name}
}

# Wait for compilation to complete and report final results
Write-Host "Waiting for compilation to complete..." -ForegroundColor Cyan
foreach ($procInfo in $processes) {
    $procInfo.Process.WaitForExit()
    if ($procInfo.Process.ExitCode -eq 0) {
        Write-Host "Successfully compiled $($procInfo.FileName)" -ForegroundColor Green
    } else {
        Write-Host "Failed compilation for $($procInfo.FileName)" -ForegroundColor Red
    }
}

# Move PDF files to main/pdfs directory
Write-Host "Moving PDF files to main/pdfs directory..." -ForegroundColor Cyan

# Create main/pdfs directory if it doesn't exist
if (!(Test-Path ".\main\pdfs")) {
    New-Item -ItemType Directory -Path ".\main\pdfs" -Force | Out-Null
    Write-Host "Created main/pdfs directory" -ForegroundColor Yellow
}

Get-ChildItem -Path "." -Name "*.pdf" | Where-Object { $_ -like "main_*" -or $_ -like "presentation*" -or $_ -like "print*" } | ForEach-Object {
    Move-Item $_ ".\main\pdfs\" -Force
    Write-Host "Moved $_ to main/pdfs directory" -ForegroundColor Yellow
}

# Clean up temporary files
Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
Get-ChildItem -Path "." -Include "*.aux","*.log","*.nav","*.out","*.snm","*.toc","*.atfi","*.fls","*.fdb_latexmk","*.synctex.gz","*.bbl","*.blg" -Recurse | Remove-Item -Force

Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host "=== Build process finished ===" -ForegroundColor Magenta
