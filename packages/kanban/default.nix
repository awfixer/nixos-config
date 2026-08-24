# Kanban CLI ("A kanban foundation for coding agents"), built from the
# vendored source in ./src with the npm toolchain.
#
# Same architecture as ../ai-daemon (cline): the fixed-output kanbanDeps
# derivation performs the one online install (root + web-ui, pinned by the
# committed package-lock.json files), and every later step works from that
# snapshot. The CLI bundle's only runtime external is node-pty, whose
# tarball ships a linux-x64 prebuilt addon — so no compilers run anywhere.
# The package wraps nixpkgs' node interpreter inside its own closure;
# nothing adds node or changes bun versions on the system.
#
# After changing deps (package-lock.json) refresh the hash:
#   nix build .#kanban 2>&1 | grep "got:"   # copy into kanbanDeps.outputHash
{
  lib,
  stdenvNoCC,
  nodejs,
  makeWrapper,
  # Runtime tools the CLI shells out to (git via simple-git/spawnSync,
  # xdg-open via the `open` package). User PATH stays available after these.
  git,
  xdg-utils,
}:

let
  pname = "kanban";
  version = "0.1.70";

  # Only what the CLI build consumes: root + web-ui installs, esbuild
  # bundling over src/, and scripts/build.mjs. packages/desktop and the
  # docs/grit/man extras are not part of `npm run build`.
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
      ./tsconfig.json
      ./tsconfig.base.json
      ./tsconfig.build.json
      ./scripts
      ./src
      ./web-ui
    ];
  };

  # Fixed-output derivation: runs the online `npm ci` once (scripts disabled
  # — nothing here needs them) and ships both installed node_modules trees.
  kanbanDeps = stdenvNoCC.mkDerivation {
    name = "${pname}-${version}-npm-deps";

    inherit src;

    nativeBuildInputs = [ nodejs ];
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

      npm ci --ignore-scripts --no-audit --no-fund
      npm --prefix web-ui ci --ignore-scripts --no-audit --no-fund

      mkdir -p $out
      cp -r node_modules $out/node_modules
      cp -r web-ui $out/web-ui
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    # Update from the "got:" line of the failed first build.
    outputHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    nodejs
    makeWrapper
  ];

  passthru = {
    inherit kanbanDeps;
  };

  configurePhase = ''
    runHook preConfigure

    # Writable locations inside the build dir (the sandbox has no /tmp).
    export TMPDIR=$PWD/.tmp
    export HOME=$PWD/.home
    export XDG_CACHE_HOME=$PWD/.cache
    mkdir -p "$TMPDIR" "$HOME" "$XDG_CACHE_HOME"

    # Restore installed dependency trees. Store paths are read-only (555);
    # vite/esbuild/npm need to write inside node_modules.
    cp -r --no-preserve=mode ${kanbanDeps}/node_modules ./node_modules
    chmod -R u+w node_modules
    mkdir -p web-ui
    cp -r --no-preserve=mode ${kanbanDeps}/web-ui/node_modules web-ui/node_modules
    chmod -R u+w web-ui/node_modules

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    # Web UI (vite from web-ui's own devDependencies; the upstream script
    # also runs tsc --noEmit, a typecheck rather than a build step).
    (
      cd web-ui
      node_modules/.bin/vite build
    )

    # Bundle the CLI + library (esbuild; external: node-pty only).
    node scripts/build.mjs

    # Static web UI ships inside dist/ (upstream copies it verbatim).
    mkdir -p dist/web-ui
    cp -r web-ui/dist/* dist/web-ui/

    # Upstream also uploads sourcemaps to Sentry here; skipped by design.

    # Drop devDependencies from the shipped runtime tree.
    npm prune --omit=dev --no-audit --no-fund

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/kanban
    cp -r dist $out/lib/kanban/dist
    cp -rL node_modules $out/lib/kanban/node_modules

    mkdir -p $out/bin
    makeWrapper ${lib.getExe nodejs} $out/bin/kanban \
      --add-flags "$out/lib/kanban/dist/cli.js" \
      --prefix PATH : ${lib.makeBinPath [
        git
        xdg-utils
      ]}

    runHook postInstall
  '';

  meta = {
    description = "Kanban board foundation for coding agents";
    homepage = "https://github.com/cline/kanban";
    license = lib.licenses.asl20;
    mainProgram = "kanban";
    platforms = [ "x86_64-linux" ];
  };
}
