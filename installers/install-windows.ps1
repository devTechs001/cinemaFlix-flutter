# CinemaFlix Windows installer — clones or updates the GitHub build.
$ErrorActionPreference = "Stop"
$Repo = "https://github.com/devTechs001/cinemaFlix-flutter.git"
$Dest = if ($env:CINEMAFLIX_HOME) { $env:CINEMAFLIX_HOME } else { Join-Path $HOME "cinemaFlix-flutter" }

Write-Host "CinemaFlix installer (Windows)"
Write-Host "→ $Dest"

if (Test-Path (Join-Path $Dest ".git")) {
  git -C $Dest fetch --depth 1 origin
  git -C $Dest reset --hard origin/main
} else {
  if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
  git clone --depth 1 $Repo $Dest
}

Write-Host ""
Write-Host "Installed source at $Dest"
Write-Host "Next:  cd $Dest ; flutter pub get ; flutter run"
