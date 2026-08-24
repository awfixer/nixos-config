# Cline CLI, built from the vendored monorepo in ./src with Bun.
#
# Everything is self-contained: dependencies come from a fixed-output
# bun cache derivation (pinned via src/bun.lock), the build runs fully
# offline, and the runtime only needs the bundled bun interpreter — no
# system node, no system bun.
#
# After changing ./src deps (bun.lock / package.json), the FOD hash must
# be refreshed:
#   nix build .#cline 2>&1 | grep "got:"    # copy into bunDeps.outputHash
{
  lib,
  stdenvNoCC,
  bun,
  makeWrapper,
  # Runtime tools the CLI shells out to (git for checkpoints/diffs, rg for
  # search, xdg-open for opening URLs). User PATH stays available after these.
  git,
  ripgrep,
  xdg-utils,
}:

let
  pname = "cline";
  version = "3.0.57";

  # Pruned monorepo: just the workspaces the CLI build needs. bun supports
  # --frozen-lockfile on pruned checkouts — workspaces whose package.json is
  # absent are skipped, so apps/vscode (better-sqlite3/grpc-tools native
  # installs) and other unused apps never enter the dependency graph.
  src = lib.fileset.toSource {
    root = ./src;
    fileset = lib.fileset.unions [
      ./src/package.json
      ./src/bun.lock
      ./src/patches
      ./src/sdk
      ./src/apps/cli
      ./src/apps/cline-hub
    ];
  };

  # Fixed-output derivation that warms the bun install cache once. Only here
  # is network access used; every later step resolves from this cache.
  bunDeps = stdenvNoCC.mkDerivation {
    name = "${pname}-${version}-bun-deps";

    inherit src;

    nativeBuildInputs = [ bun ];
    impureEnvVars = lib.fetchers.proxyImpureEnvVars;
    preferLocalBuild = true;

    buildCommand = ''
      export HOME=$TMPDIR/home
      mkdir -p "$HOME"
      export BUN_INSTALL_CACHE_DIR=$TMPDIR/bun-cache

      bun install --frozen-lockfile --ignore-scripts

      mkdir -p $out
      cp -r "$BUN_INSTALL_CACHE_DIR" $out/cache
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    # Update from the "got:" line of the failed first build.
    outputHash = lib.fakeHash;
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    bun
    makeWrapper
  ];

  passthru = {
    inherit bunDeps;
  };

  configurePhase = ''
    runHook preConfigure

    export HOME=$TMPDIR/home
    export XDG_CACHE_HOME=$TMPDIR/xdg-cache
    mkdir -p "$HOME" "$XDG_CACHE_HOME"

    # Restore the warmed cache; --offline makes any cache miss a hard error
    # instead of a silent fetch, keeping the build deterministic.
    export BUN_INSTALL_CACHE_DIR=$XDG_CACHE_HOME/bun-install
    cp -r ${bunDeps}/cache/. "$BUN_INSTALL_CACHE_DIR"/

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    bun install --offline --frozen-lockfile --ignore-scripts

    # SDK packages first: the CLI bundle imports their dist/ exports and
    # copies core's plugin-sandbox-bootstrap.js out of them.
    bun run build:sdk
    bun -F @cline/cli build

    # Drop devDependencies (vitest, swc, tui-test, ...) from node_modules;
    # production closure is what ships next to the bundle.
    bun prune --production

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/cline
    cp -r apps/cli/dist $out/lib/cline/dist
    cp apps/cli/package.json $out/lib/cline/package.json
    cp -r node_modules $out/lib/cline/node_modules

    mkdir -p $out/bin
    makeWrapper ${lib.getExe bun} $out/bin/cline \
      --add-flags "$out/lib/cline/dist/index.js" \
      --prefix PATH : ${lib.makeBinPath [
        git
        ripgrep
        xdg-utils
      ]}

    runHook postInstall
  '';

  meta = {
    description = "Autonomous coding agent CLI (built from vendored cline source)";
    homepage = "https://cline.bot";
    license = lib.licenses.asl20;
    mainProgram = "cline";
    platforms = [ "x86_64-linux" ];
  };
}
