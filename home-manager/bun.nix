{
  home.file.".grok/plugins/bun".source = ../ai/bun;

  home.file.".bunfig.toml".text = ''
    [install]
    registry = "https://registry1.solved.gg"
    minimumReleaseAge = 259200
    minimumReleaseAgeExcludes = [
      "railway",
      "clerk",
      "@clerk/cli-linux-x64",
      "@tiptap/cli",
    ]
    optional = false
    peer = false
    exact = true
    ignoreScripts = true
    auto = "disable"
    prefer = "offline"
    linkWorkspacePackages = true


    [run]
    shell = "bun"
    noOrphans = true

    [test]
    coverageThreshold = 0.9

  '';
}
