#Requires -Modules Logging

# Create the server ini (MF_INI, default System/Server.ini) from the game's MobileForces.ini on
# first start, then write the MF_* settings into it. It's created through the merged view, so it
# lands in Overlay/ and can be edited there; keys without an MF_* setting are never touched.

$system   = Join-Path $Env:SERVER_ROOT 'System'
$template = Join-Path $system 'MobileForces.ini'
$ini      = Join-Path $system $Env:MF_INI

if (-not (Test-Path -Path $ini)) {
    if (-not (Test-Path -Path $template)) {
        Write-Log -Level Error "$template not found; skipping server configuration"
        return
    }

    Copy-Item -Path $template -Destination $ini
    Write-Log "Created $ini from MobileForces.ini"
}

$text    = [System.IO.File]::ReadAllText($ini)
$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$lines   = [System.Collections.Generic.List[string]]::new([string[]]($text -split "\r?\n"))

# Set Key=Value in [Section], replacing the first existing Key= line or appending to the section
function Set-IniValue([string] $Section, [string] $Key, [string] $Value) {
    $start = $lines.IndexOf("[$Section]")
    if ($start -lt 0) {
        $lines.Add("[$Section]")
        $lines.Add("$Key=$Value")
        return
    }

    $end = $start + 1
    while ($end -lt $lines.Count -and -not $lines[$end].StartsWith('[')) { $end++ }

    for ($i = $start + 1; $i -lt $end; $i++) {
        if ($lines[$i] -like "$Key=*") {
            $lines[$i] = "$Key=$Value"
            return
        }
    }

    # Insert after the section's last non-blank line
    $at = $end
    while ($at -gt $start + 1 -and [string]::IsNullOrWhiteSpace($lines[$at - 1])) { $at-- }
    $lines.Insert($at, "$Key=$Value")
}

$settings = @(
    @('URL',                         'Port',         $Env:MF_PORT),
    @('Engine.GameReplicationInfo',  'ServerName',   $Env:MF_SERVER_NAME),
    @('Engine.GameReplicationInfo',  'ShortName',    $Env:MF_SHORT_NAME),
    @('Engine.GameReplicationInfo',  'AdminName',    $Env:MF_ADMIN_NAME),
    @('Engine.GameReplicationInfo',  'AdminEmail',   $Env:MF_ADMIN_EMAIL),
    @('Engine.GameReplicationInfo',  'MOTDLine1',    $Env:MF_MOTD),
    @('Engine.GameInfo',             'MaxPlayers',   $Env:MF_MAX_PLAYERS),
    @('Engine.GameInfo',             'GamePassword', $Env:MF_GAME_PASSWORD),
    @('Engine.GameInfo',             'AdminPassword', $Env:MF_ADMIN_PASSWORD)
)

foreach ($s in $settings) {
    if ($s[2]) { Set-IniValue $s[0] $s[1] $s[2] }
}

# GameSpy is gone, so by default drop the master server uplinks (they only fail DNS/heartbeat)
if ($Env:MF_MASTER_SERVER_UPLINK -notin @('true', '1', 'yes')) {
    $removed = $lines.RemoveAll({ param($l) $l -like 'ServerActors=IpServer.UdpServerUplink*' })
    if ($removed) { Write-Log "Removed $removed master server uplink(s) from $Env:MF_INI" }
    Set-IniValue 'IpServer.UdpServerUplink' 'DoUplink' 'False'
}

[System.IO.File]::WriteAllText($ini, ($lines -join $newline))
chown "$($Env:UID):$($Env:GID)" $ini

Write-Log "Applied MF_* settings to $ini"
