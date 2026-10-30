# syntax=docker/dockerfile:1.7

# Override to build against a locally built base, e.g. lancommander/wine:local
ARG BASE_IMAGE=lancommander/wine:latest
FROM ${BASE_IMAGE}

# ----------------------------
# Server settings
#   - The game files are not downloadable; put a Mobile Forces (patch 20000) install in
#     /config/Server, or set MF_ARCHIVE_URL to a zip of one
#   - MF_INI is created from System/MobileForces.ini on first start; the MF_* settings below are
#     written into it on every start (empty settings are left alone)
# ----------------------------
ENV MF_ARCHIVE_URL="" \
    MF_MAP="mf-Carpark" \
    MF_GAME_TYPE="RageGame.RageCTF" \
    MF_PORT="7777" \
    MF_INI="Server.ini" \
    MF_SERVER_NAME="Mobile Forces Server" \
    MF_SHORT_NAME="MF Server" \
    MF_ADMIN_NAME="" \
    MF_ADMIN_EMAIL="" \
    MF_MOTD="" \
    MF_MAX_PLAYERS="16" \
    MF_GAME_PASSWORD="" \
    MF_ADMIN_PASSWORD="" \
    MF_MASTER_SERVER_UPLINK="false" \
    MF_URL_OPTIONS="" \
    START_EXE="/usr/local/bin/mf-server" \
    START_ARGS=""

COPY Scripts/mf-server /usr/local/bin/mf-server
RUN chmod +x /usr/local/bin/mf-server

COPY Hooks/ "${BASE_HOOKS}/"

# 7777/udp: game. 7778/udp: server query (game port + 1). 8777/udp: LAN browser beacon (UdpBeacon
# answers REPORTQUERY broadcasts there).
EXPOSE 7777/udp 7778/udp 8777/udp

WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.ps1"]
