# update_icons_fixed.ps1
Add-Type -AssemblyName System.Drawing

$source = "assets\logo\jarvis_green_logo_transparent.png"
if (-not (Test-Path $source)) {
    Write-Host "❌ Logo not found at: assets\logo\jarvis_green_logo_transparent.png" -ForegroundColor Red
    Write-Host "   Please copy your logo to assets\logo\jarvis_green_logo_transparent.png" -ForegroundColor Yellow
    exit
}

$sizes = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($dir in $sizes.Keys) {
    $size = $sizes[$dir]
    $targetDir = "android\app\src\main\res\$dir"
    $targetPath = "$targetDir\ic_launcher.png"
    
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Host "📁 Created directory: $targetDir" -ForegroundColor Yellow
    }
    
    if (Test-Path $targetPath) {
        Remove-Item $targetPath -Force -ErrorAction SilentlyContinue
    }
    
    try {
        $img = [System.Drawing.Image]::FromFile((Resolve-Path $source))
        $resized = New-Object System.Drawing.Bitmap($img, $size, $size)
        $resized.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $resized.Dispose()
        $img.Dispose()
        Write-Host "✅ Created: $targetPath (${size}x${size})" -ForegroundColor Green
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Host "❌ Failed to create $targetPath" -ForegroundColor Red
        Write-Host "   Error: $errorMsg" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ Icon update complete!" -ForegroundColor Green
Write-Host "📝 Now run: flutter clean && flutter run" -ForegroundColor Yellow
