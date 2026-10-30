# Mobile Forces Server (Docker)

This repository provides a Dockerized **Mobile Forces** dedicated server. Mobile Forces (Rage Games, 2002) is an Unreal Engine 1 game with no Linux server, so the image runs the game's own `UCC.exe server` under Wine.
The image builds on [`lancommander/wine`](https://github.com/LANCommander/LANCommander.Servers.WINE). It supports file overlaying using OverlayFS.

---

## Features

- Runs the retail game's `UCC.exe server` (headless; no graphics or sound are initialized)
- A separate server ini (`System/Server.ini`) is created from the game's `MobileForces.ini`, and the common settings are environment variables
- The dead GameSpy master server uplinks are removed by default
- UCC's console log goes to `docker logs`
- Supports file overlaying using OverlayFS (no file copying required)

## Docker Compose Example

```yaml
services:
  mobileforces:
    image: lancommander/mobileforces:latest
    container_name: mobileforces

    ports:
      - "7777:7777/udp"
      - "7778:7778/udp"
      - "8777:8777/udp"

    volumes:
      - ./config:/config

    environment:
      MF_SERVER_NAME: "My Mobile Forces Server"
      MF_MAP: "mf-Carpark"
      MF_GAME_TYPE: "RageGame.RageCTF"
      MF_MAX_PLAYERS: "16"

    user: root
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined

    restart: unless-stopped
```

The in-game LAN browser finds servers by broadcast. That needs the container on the LAN itself (macvlan/ipvlan, or `network_mode: host`); with port mapping, clients join by IP.

---

## Game Files

Mobile Forces is retail software with no public download. You must provide an install patched to **20000** (the GOG release is):

- copy the game folder (the one containing `System/`, `maps/`, `Textures/` ...) to `config/Server/`, **or**
- set `MF_ARCHIVE_URL` to a zip of that folder, e.g. a LANCommander archive. It is downloaded and extracted on first start, if `Server/System/UCC.exe` doesn't exist yet.

## Directory Layout (Host)

```text
.
└── config/
    ├── Server/            # Mobile Forces install (System/, maps/, Textures/ ...)
    ├── Overlay/           # Your files, layered on top of Server/ (System/Server.ini and server.log land here)
    ├── Merged/            # Overlayfs merged view (auto-created, the server runs here)
    ├── wineprefix/        # Wine prefix (auto-created)
    └── Scripts/
        └── Hooks/         # PowerShell scripts run at container lifecycle hooks
```

---

## Environment Variables

These are in addition to the [WINE image's variables](https://github.com/LANCommander/LANCommander.Servers.WINE#environment).
The ini settings are written into `MF_INI` on every start. Settings left empty are not touched, so you can set them in the ini instead.

| Variable | Description | Default |
|----------|-------------|---------|
| `MF_MAP` | Start map (`mf-airport`, `mf-Carpark`, `mf-dockyard`, `mf-Ghetto`, `mf-Hydroworks`, `mf-Polar`, `mf-Rail_Quarry`, `mf-sawmill`, `mf-warehouse`, `mf-waterfront`, `mf-western`) | `mf-Carpark` |
| `MF_GAME_TYPE` | Game class, see below | `RageGame.RageCTF` |
| `MF_URL_OPTIONS` | Extra map URL options, e.g. `MaxPlayers=8?GamePassword=x` | |
| `MF_INI` | Server ini in `System/`, created from `MobileForces.ini` if missing | `Server.ini` |
| `MF_PORT` | Game port, `[URL] Port`. The query port is this + 1 | `7777` |
| `MF_SERVER_NAME` | `[Engine.GameReplicationInfo] ServerName` | `Mobile Forces Server` |
| `MF_SHORT_NAME` | `[Engine.GameReplicationInfo] ShortName` | `MF Server` |
| `MF_ADMIN_NAME` | `[Engine.GameReplicationInfo] AdminName` | |
| `MF_ADMIN_EMAIL` | `[Engine.GameReplicationInfo] AdminEmail` | |
| `MF_MOTD` | `[Engine.GameReplicationInfo] MOTDLine1` | |
| `MF_MAX_PLAYERS` | `[Engine.GameInfo] MaxPlayers` | `16` |
| `MF_GAME_PASSWORD` | `[Engine.GameInfo] GamePassword` | |
| `MF_ADMIN_PASSWORD` | `[Engine.GameInfo] AdminPassword` | |
| `MF_MASTER_SERVER_UPLINK` | `true` keeps the `UdpServerUplink` server actors (GameSpy) | `false` |
| `MF_ARCHIVE_URL` | Zip of the game folder, used if `Server/System/UCC.exe` is missing | |
| `START_EXE` | Launcher | `/usr/local/bin/mf-server` |
| `START_ARGS` | Appended to the UCC command line | |

Game types: `Rage.RageDeathMatch` (Deathmatch), `Rage.RageTeamGame` (Team Deathmatch), `RageGame.RageCTF` (Capture the Flag), `RageGame.RageCaptains`, `RageGame.RageDomination` (Holdout), `RageGame.RageDetonation` (Detonation), `RageGame.RageSafeCracker` (Safecracker), `RageGame.TrailerGame` (Trailer). Per-mode rules (frag/score limit, time limit, bots) are in the matching `[RageGame.*]` / `[Rage.*]` section of the server ini.

See [Documentation/Docker.md](Documentation/Docker.md) for more detail.

---

## Building

The image is built `FROM lancommander/wine:latest` by default. To build against a local base image:

```bash
docker build --build-arg BASE_IMAGE=lancommander/wine:local -t lancommander/mobileforces:local .
```

---

## License

Mobile Forces and Wine are distributed under their respective licenses.
This repository contains only Docker build logic and helper scripts licensed under MIT.
