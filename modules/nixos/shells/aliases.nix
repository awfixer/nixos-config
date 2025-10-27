let
  aliasList = [
    { name = "g"; value = "git"; }
    { name = "clean"; value = "sudo nix-collect-garbage -d"; }
    { name ="flake"; value = "clean && sudo nixos-rebuild switch --flake . --impure --verbose --upgrade"; }
    { name = "ll"; value = "ls -lha"; }
    { name = "cp"; value = "cp -r"; }
    { name = "dinit"; value = "devbox init"; }
    { name = "cd"; value = "z"; }
    { name = "c"; value = "clear"; }
    { name = "h"; value = "history"; }
    { name = "dka"; value = "docker kill $(docker ps -qa) 2> /dev/null"; }
    { name = "dra"; value = "docker rm -f $(docker ps -qa) 2> /dev/null"; }
    { name = "dkra"; value = "dka; dra"; }
    { name = "dria"; value = "docker rmi -f $(docker image ls -qa)"; }
    { name = "dils"; value = "docker image ls"; }
    { name = "dcp"; value = "docker cp"; }
    { name = "dps"; value = "docker ps -a"; }
    { name = "dl"; value = "docker logs"; }
    { name = "ld"; value = "lazydocker"; }
  ];
in
builtins.listToAttrs (map (a: { name = a.name; value = a.value; }) aliasList)
