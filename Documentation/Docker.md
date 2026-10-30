---
sidebar_label: Docker
---

# Mobile Forces Docker Container

This Docker container runs a Mobile Forces dedicated server. It is built on the WINE image and runs the retail game's Unreal Engine 1 server, `UCC.exe server`. The container doesn't download the game, so you provide the files.

## Quick Start

```yaml
services:
  mobileforces:
    image: lancommander/mobileforces:latest
    container_name: mobileforces

    ports:
      - 7777:7777/udp
      - 7778:7778/udp
      - 8777:8777/udp

    volumes:
      - "/data/Servers/Mobile Forces/CTF:/config"

    environment:
      MF_SERVER_NAME: "My Mobile Forces Server"
      MF_MAP: "mf-Carpark"
      MF_GAME_TYPE: "RageGame.RageCTF"

    user: root
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined

    restart: unless-stopped
```

Copy a Mobile Forces install patched to **20000** (the folder with `System/UCC.exe` and `maps/`) into `Server/` before the first start. You can instead set `MF_ARCHIVE_URL` to a zip of that folder.

## How It Starts

1. `PostInitialization/10-InitializeWinePrefix.ps1` (from the WINE image) creates the Wine prefix in `/config/wineprefix`.
2. `PostInitialization/20-InstallMobileForces.ps1` checks for `Server/System/UCC.exe`. If it's missing and `MF_ARCHIVE_URL` is set, the hook downloads and extracts the archive and remounts the overlay.
3. `PostInitialization/30-ConfigureMobileForces.ps1` copies `System/MobileForces.ini` to `System/Server.ini` (`MF_INI`) if it doesn't exist yet. It does this through `Merged/`, so the file lands in `Overlay/System/`. It then writes the non-empty `MF_*` settings into it and removes the GameSpy uplink server actors.
4. `START_EXE` (`/usr/local/bin/mf-server`) runs `UCC.exe server <MF_MAP>?Game=<MF_GAME_TYPE> ini=Server.ini log=server.log` from `System/` under Wine.

A successful start ends with:

```
Game class is 'RageCTF'
TcpNetDriver on port 7777
...
UdpServerQuery(crt): Port 7778 successfully bound.
Game engine initialized
```

## Configuration Options

### Ports

- **7777/udp**: Game (`MF_PORT`)
- **7778/udp**: Server query, GameSpy protocol (game port + 1)
- **8777/udp**: LAN beacon. The in-game LAN browser broadcasts `REPORTQUERY` here (`[IpDrv.UdpBeacon] ServerBeaconPort`). The server also broadcasts to 7776.

### Environment Variables

See the [README](../README.md#environment-variables) for the full table.

### Server ini

`Overlay/System/Server.ini` is yours to edit. Only the keys that have a non-empty `MF_*` variable are rewritten on start. Mode rules are per game type, for example `[RageGame.RageCTF] FragLimit` (captures to win) or `[Rage.RageDeathMatch] InitialBots`. Delete the file to regenerate it from `MobileForces.ini`.

UCC saves its config to the server ini on exit, so values can also change there after a map vote or admin command.

### Hooks

| Hook | When |
|------|------|
| `PreInstallMobileForces` / `PostInstallMobileForces` | Around the game file check/download |
| `PreInitializeWinePrefix` / `PostInitializeWinePrefix` | Around Wine prefix creation (WINE image) |

Put `.ps1` scripts in `config/Scripts/Hooks/<HookName>/`.

## Troubleshooting

- **Server not in the LAN browser**: the browser finds servers by UDP broadcast to 8777, so the container needs its own LAN address (macvlan/ipvlan) or host networking. Joining by IP (`open <ip>:7777` in the console) works through port mapping.
- **Settings ignored**: they go into `MF_INI`, not `MobileForces.ini`. Check `Overlay/System/Server.ini`.
- **`System/UCC.exe not found`**: `Server/` must contain the game folder itself (`Server/System/UCC.exe`), not a folder that contains it.
