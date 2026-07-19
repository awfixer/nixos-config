{
  config,
  lib,
  pkgs,
  ...
}:

# System Playwright + Prisma tooling for NixOS.
# npm/bun local installs honor these env vars and skip downloading broken
# prebuilt engines/browsers (see wiki.nixos.org/wiki/Playwright and the
# prisma-engines setup-hook in nixpkgs).
let
  playwrightBrowsers = pkgs.playwright-driver.browsers;
  prismaEngines = pkgs.prisma-engines; # alias → prisma-engines_7
in
{
  environment.systemPackages = with pkgs; [
    playwright-test # `playwright` CLI, default BROWSERS_PATH
    prisma # `prisma` CLI, wraps schema-engine
    prisma-engines # engines + setup-hook for nix shells
  ];

  environment.sessionVariables = {
    # Playwright (npm / bun / @playwright/test)
    PLAYWRIGHT_BROWSERS_PATH = "${playwrightBrowsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";

    # Prisma (npm / bun local CLI uses these instead of downloaded engines)
    PRISMA_SCHEMA_ENGINE_BINARY = "${prismaEngines}/bin/schema-engine";
  };

  # Ensure login shells and non-interactive systemd user sessions also see them.
  environment.variables = {
    PLAYWRIGHT_BROWSERS_PATH = "${playwrightBrowsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
    PRISMA_SCHEMA_ENGINE_BINARY = "${prismaEngines}/bin/schema-engine";
  };
}
