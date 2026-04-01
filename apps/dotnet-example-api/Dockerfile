# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

COPY src/Api/Api.csproj ./

RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages <<EOT
    dotnet restore Api.csproj
EOT

COPY /src/Api/ ./

RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages <<EOT
    dotnet build Api.csproj \
        --nologo \
        --no-restore \
        --configuration Release
EOT

RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages <<EOT
    dotnet publish Api.csproj \
        --nologo \
        --no-build \
        --configuration Release \
        --output /publish
EOT

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base

ARG TARGETARCH
ARG DATADOG_VERSION="3.33.0"

ENV ARCH_SHORT=${TARGETARCH/amd64/x64}

RUN <<EOT
    set -o errexit &&
    ARCH=$(uname -m) &&
    if [ "${ARCH}" = "aarch64" ]; then ARCH="arm64"; fi &&
    if [ "${ARCH}" = "amd64" ] || [ "${ARCH}" = "x86_64" ]; then ARCH="amd64"; fi &&
    DATADOG_DEB_URL="https://github.com/DataDog/dd-trace-dotnet/releases/download/v${DATADOG_VERSION}/datadog-dotnet-apm_${DATADOG_VERSION}_${ARCH}.deb" &&
    apt-get update &&
    apt-get install --yes curl &&
    curl \
        --fail \
        --silent \
        --location \
        --output /tmp/datadog-dotnet-apm.deb \
        "${DATADOG_DEB_URL}" &&
    apt-get purge --yes --auto-remove curl && \
    rm -rf /var/lib/apt/lists/* &&
    dpkg --install /tmp/datadog-dotnet-apm.deb &&
    rm /tmp/datadog-dotnet-apm.deb
EOT

ENV LD_PRELOAD="/opt/datadog/linux-${ARCH_SHORT}/Datadog.Linux.ApiWrapper.x64.so"
ENV CORECLR_PROFILER={846F5F1C-F9AE-4B07-969E-05C26BC060D8}
ENV CORECLR_PROFILER_PATH=/opt/datadog/Datadog.Trace.ClrProfiler.Native.so
ENV CORECLR_ENABLE_PROFILING=0
ENV DD_SITE=us5.datadoghq.com
ENV DD_DOTNET_TRACER_HOME=/opt/datadog
ENV DD_PROFILING_ALLOCATION_ENABLED=false
ENV DD_PROFILING_ENABLED=false
ENV DD_RUNTIME_METRICS_ENABLED=false
ENV DD_LOGS_INJECTION=true
ENV DD_CODE_ORIGIN_FOR_SPANS_ENABLED=false
ENV DD_APM_ENABLED=false

FROM base AS runtime
ENV ASPNETCORE_URLS=http://*:8080
WORKDIR /app
COPY --from=build /publish/ /app/
RUN chown --recursive "${APP_UID}:${APP_UID}" /app
USER "${APP_UID}"
ENTRYPOINT ["dotnet", "Api.dll"]
