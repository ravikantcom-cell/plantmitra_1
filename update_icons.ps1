# update_icons.ps1
Write-Host "🔄 Starting icon update for Jarvis Green..." -ForegroundColor Green

$sourceLogo = "assets\logo\jarvis_green_logo_transparent.png"

# Check if source exists
if (-not (Test-Path $sourceLogo)) {
    Write-Host "❌ Source logo not found at: $sourceLogo" -ForegroundColor Red
    exit
}

# Try to get image dimensions using PowerShell
Add-Type -AssemblyName System.Drawing
try {
    $img = [System.Drawing.Image]::FromFile((Resolve-Path $sourceLogo))
    $width = $img.Width
    $height = $img.Height
    $img.Dispose()
    Write-Host "✅ Logo dimensions: ${width}x${height}" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not read image dimensions" -ForegroundColor Yellow
}

# Create all required sizes using System.Drawing
$sizes = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($dir in $sizes.Keys) {
    $size = $sizes[$dir]
    $targetPath = "android\app\src\main\res\$dir\ic_launcher.png"
    
    # Create directory if it doesn't exist
    $targetDir = Split-Path $targetPath -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    # Load image and resize
    try {
        $img = [System.Drawing.Image]::FromFile((Resolve-Path $sourceLogo))
        $resized = new-object System.Drawing.Bitmap($img, $size, $size)
        $resized.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $resized.Dispose()
        $img.Dispose()
        Write-Host "✅ Created: $targetPath (${size}x${size})" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create $targetPath: $_" -ForegroundColor Red
    }
}

# Create the adaptive icon configuration
Write-Host "`n📁 Creating adaptive icon configuration..." -ForegroundColor Green

# Create mipmap-anydpi-v26 folder
$adaptiveDir = "android\app\src\main\res\mipmap-anydpi-v26"
New-Item -ItemType Directory -Path $adaptiveDir -Force | Out-Null

# Create ic_launcher.xml
@"
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher"/>
</adaptive-icon>
"@ | Out-File -FilePath "$adaptiveDir\ic_launcher.xml" -Encoding UTF8
Write-Host "✅ Created: $adaptiveDir\ic_launcher.xml" -ForegroundColor Green

# Create colors.xml
$valuesDir = "android\app\src\main\res\values"
New-Item -ItemType Directory -Path $valuesDir -Force | Out-Null
@"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#2E7D32</color>
</resources>
"@ | Out-File -FilePath "$valuesDir\colors.xml" -Encoding UTF8
Write-Host "✅ Created: $valuesDir\colors.xml" -ForegroundColor Green

# Create strings.xml
@"
<resources>
    <string name="app_name">Jarvis Green</string>
</resources>
"@ | Out-File -FilePath "$valuesDir\strings.xml" -Encoding UTF8
Write-Host "✅ Created: $valuesDir\strings.xml" -ForegroundColor Green

Write-Host "`n✅ Icon update complete!" -ForegroundColor Green
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: flutter clean" -ForegroundColor Yellow
Write-Host "2. Run: flutter pub get" -ForegroundColor Yellow
Write-Host "3. Run: flutter run" -ForegroundColor Yellow