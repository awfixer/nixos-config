{
  lib,
  python3Packages,
  nodejs_latest,
  fetchurl,
  buildNpmPackage,
  makeWrapper,
}:

let
  chrome-devtools-mcp = buildNpmPackage rec {
    pname = "chrome-devtools-mcp";
    version = "1.7.0";

    # GitHub tag v1.7.0 does not exist. npm 1.7.0 gitHead is
    # 774d78f5eef5e610407a0c92fa6ec5ed74b027e8 (chrome-devtools-mcp-v1.7.0).
    # The published tarball is a rollup bundle; the GitHub tree needs the
    # devtools-frontend submodule plus a TypeScript compile.
    src = fetchurl {
      url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-${version}.tgz";
      hash = "sha256-iVczWGoOzhOEk3kMB+iwg7hXGx0gN6cxJDNNlo0QRtA=";
    };

    # Tarball has no lockfile and no production deps. Drop prepare/dev tooling
    # so npm ci does not try to fetch puppeteer/lighthouse/typescript.
    postPatch = ''
      cat > package.json <<'EOF'
{
  "name": "chrome-devtools-mcp",
  "version": "1.7.0",
  "description": "MCP server for Chrome DevTools",
  "type": "module",
  "bin": {
    "chrome-devtools-mcp": "./build/src/bin/chrome-devtools-mcp.js",
    "chrome-devtools": "./build/src/bin/chrome-devtools.js"
  },
  "main": "./build/src/index.js",
  "files": [
    "build/src",
    "LICENSE",
    "skills",
    "!*.tsbuildinfo",
    "!*.js.map"
  ],
  "repository": "ChromeDevTools/chrome-devtools-mcp",
  "author": "Google LLC",
  "license": "Apache-2.0",
  "bugs": {
    "url": "https://github.com/ChromeDevTools/chrome-devtools-mcp/issues"
  },
  "homepage": "https://github.com/ChromeDevTools/chrome-devtools-mcp#readme",
  "mcpName": "io.github.ChromeDevTools/chrome-devtools-mcp",
  "engines": {
    "node": "^20.19.0 || ^22.12.0 || >=23"
  }
}
EOF
      cat > package-lock.json <<'EOF'
{
  "name": "chrome-devtools-mcp",
  "version": "1.7.0",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "chrome-devtools-mcp",
      "version": "1.7.0",
      "license": "Apache-2.0",
      "bin": {
        "chrome-devtools": "build/src/bin/chrome-devtools.js",
        "chrome-devtools-mcp": "build/src/bin/chrome-devtools-mcp.js"
      },
      "engines": {
        "node": "^20.19.0 || ^22.12.0 || >=23"
      }
    }
  }
}
EOF
    '';

    forceEmptyCache = true;
    dontNpmBuild = true;
    dontNpmPrune = true;
    # npmInstallHook deletes an empty node_modules/ then cp's it.
    preInstall = ''
      mkdir -p node_modules
      touch node_modules/.keep
    '';

    npmDepsHash = "sha256-tow/ir6++u8kDSYp4wDYZ9fvK9Z0nw9/QzqVN6uPIfs=";
    nodejs = nodejs_latest;

    meta = {
      description = "Chrome DevTools MCP server";
      homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    };
  };

  # stdio_client sanitizes the child env (no PYTHONPATH). The fake MCP server
  # is launched with sys.executable, so the check interpreter must have mcp
  # on its own site-packages.
  pythonForTests = python3Packages.python.withPackages (
    ps: with ps; [
      pytest
      pytest-asyncio
      aiohttp
      mcp
      uvicorn
      starlette
    ]
  );
in
python3Packages.buildPythonApplication rec {
  pname = "helium-devtools";
  version = "0.1.0";
  src = ./.;
  pyproject = true;

  nativeBuildInputs = [
    python3Packages.setuptools
    makeWrapper
  ];

  propagatedBuildInputs = with python3Packages; [
    aiohttp
    mcp
    uvicorn
    starlette
  ];

  nativeCheckInputs = with python3Packages; [
    pytestCheckHook
    pytest-asyncio
    pythonForTests
  ];

  pytestFlags = [ "tests" ];

  # pytestCheckHook uses the unwrapped python; the stdio child then cannot
  # import mcp. Run the same tests with pythonForTests so sys.executable works.
  dontUsePytestCheck = true;
  installCheckPhase = ''
    runHook preCheck
    ${pythonForTests.interpreter} -m pytest tests
    runHook postCheck
  '';

  # wrapProgram in postInstall would wrap the unwrapped script; wrapPythonPrograms
  # then skips it (no python shebang) and PYTHONPATH is lost. makeWrapperArgs
  # are applied by wrapPythonPrograms.
  makeWrapperArgs = [
    "--set"
    "HELIUM_DEVTOOLS_CDP_MCP"
    "${chrome-devtools-mcp}/bin/chrome-devtools-mcp"
    "--set"
    "CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS"
    "1"
    "--set"
    "CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS"
    "1"
  ];

  meta = {
    description = "CDP shim + MCP aggregator for daily Helium";
    mainProgram = "helium-devtools";
  };
}
