# Cline CLI, built from the vendored monorepo in ./src with Bun.
#
# Self-contained: the fixed-output bunDeps derivation performs the one
# online install (deps pinned via src/bun.lock), and everything after it —
# build, prune, runtime — works from that node_modules snapshot. The
# package ships its own nixpkgs bun interpreter; no system node or system
# bun is used or modified.
#
# After changing ./src deps (bun.lock / package.json) refresh the hash:
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

  # Keep every workspace: bun errors when a root package.json workspace glob
  # resolves to nothing, so apps cannot simply be deleted. Unused apps are
  # neutralised instead — lifecycle scripts never run (--ignore-scripts), so
  # nothing native (better-sqlite3, grpc-tools, playwright browsers) is built
  # or fetched — and dev-only packages are pruned before anything ships.
  src = lib.fileset.toSource {
    root = ./src;
    fileset = lib.fileset.unions [
      ./src/package.json
      ./src/bun.lock
      ./src/patches
      ./src/apps
      ./src/sdk
    ];
  };

  # Fixed-output derivation: runs the online `bun install` once and ships
  # the installed node_modules tree (content-hashed, so it is built at most
  # once per lockfile change and shared via the substituter).
  bunDeps = stdenvNoCC.mkDerivation {
    name = "${pname}-${version}-bun-deps";

    inherit src;

    nativeBuildInputs = [ bun ];
    impureEnvVars = lib.fetchers.proxyImpureEnvVars;
    preferLocalBuild = true;

    buildCommand = ''
      export HOME=$PWD/.home
      export XDG_CACHE_HOME=$PWD/.cache
      mkdir -p "$HOME" "$XDG_CACHE_HOME"

      # Explicit unpack: with only buildCommand set, this derivation does
      # not go through the generic unpack phase.
      cp -a --no-preserve=mode "$src"/. .
      chmod -R u+w .

      bun install --frozen-lockfile --ignore-scripts

      # Bun's (default, since 1.3) isolated linker gives every workspace its
      # own node_modules (root, apps/*, sdk/*) holding the @cline/* workspace
      # links — ship all of them, paths preserved.
      mkdir -p $out
      find . -type d -name node_modules -prune | while read -r t; do
        cp -a --parents "$t" $out/
      done
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    # Update from the "got:" line of the failed first build.
    outputHash = "sha256-T5svQeh+bG2Wcm7m9qEwjbr8is1/dmHcZiOqQGbs85I=";
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

    # Keep every writable location bun touches inside the build dir: the
    # sandbox has no writable /tmp and TMPDIR is not exported to the builder.
    export TMPDIR=$PWD/.tmp
    export HOME=$PWD/.home
    export XDG_CACHE_HOME=$PWD/.cache
    mkdir -p "$TMPDIR" "$HOME" "$XDG_CACHE_HOME"

    # Restore every installed node_modules tree (root + per-workspace).
    # Store paths are read-only (555); bun/tsc/vite need write access.
    for t in $(cd ${bunDeps} && find . -type d -name node_modules -prune); do
      mkdir -p "$(dirname "$t")"
      cp -a --no-preserve=mode "${bunDeps}/$t" "$t"
    done
    chmod -R u+w .

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

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

    # Mirror the workspace-relative layout: the bundle's external imports
    # (react, @opentui/*) resolve through apps/cli/node_modules up into the
    # root node_modules/.bun store, so both travel together untouched.
    mkdir -p $out/lib/cline
    cp -a --parents node_modules apps/cli/package.json apps/cli/dist \
      $out/lib/cline/

    mkdir -p $out/bin
    makeWrapper ${lib.getExe bun} $out/bin/cline \
      --add-flags "$out/lib/cline/apps/cli/dist/index.js" \
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
