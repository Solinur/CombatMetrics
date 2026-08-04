# Runs the Taneth suites under ESOLua, outside the game.
#
# Usage: .\run.ps1 [suiteId ...]
#
# Bypasses Taneth's own Taneth.bat, which does not quote its paths and so breaks on the space in
# "Elder Scrolls Online". Manifest paths are relative to the AddOns directory.
#
# Only this addon is loaded. Each spec pulls in the specific LibCombat2 files it needs via
# CMXTest.RequireLibCombat, so the game-dependent modules never have to load.

$ErrorActionPreference = "Stop"

$AddOns = "$env:USERPROFILE\Documents\Elder Scrolls Online\live\AddOns"
$EsoUiSource = "$env:USERPROFILE\Documents\ESOdev\ESO Source\esoui"
$EsoLua = "$env:USERPROFILE\Documents\ESOdev\Tools\ESOLua-1.1.0\esolua.exe"

$Manifest = "CombatMetricsTests/CombatMetricsTests.addon"

if (-not (Test-Path $EsoLua)) { throw "esolua.exe not found at $EsoLua" }
if (-not (Test-Path "$AddOns\Taneth\run.lua")) { throw "Taneth addon not found in $AddOns" }
if (-not (Test-Path "$AddOns\CombatMetricsTests\CombatMetricsTests.addon")) {
    throw "CombatMetricsTests is not linked into $AddOns"
}

Push-Location $AddOns
try {
    & $EsoLua -s $EsoUiSource -- "Taneth/run.lua" $Manifest @args
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
