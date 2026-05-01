{ ... }:

{
  programs.chromium = {
    enable = true;
    extraOpts = {
          DnsOverHttpsMode = "secure";
          DnsOverHttpsTemplates = "https://dns.nextdns.io/cf3f3e";
          BuiltInDnsClientEnabled = false;
          DnsOverHttpsFallbackToSystem = false;
        };
    extensions = [
      "ihcppnlmkfeclmehgdhjkglkbmiemnmp"
      "eimadpbcbfnmbkopoojfekhnkhdbieeh"
      "agleiimpggapjekcdhdjbmegjbbkleie"
      "cnjifjpddelmedmihgijeibhnjfabmlf"
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa"
      "adjiklnjodbiaioggfpbpkhbfcnhgkfe"
      "fllaojicojecljbmefodhfapmkghcbnh"
      "dcplinogpijcknhlmnlhnogocpfbohfi"
      "dlhckcablohllindinahbbpnfgblimoe"
      "bamhebecdlhhkedgncapjoofbohgiogc"
      "mendokngpagmkejfpmeellpppjgbpdaj"
      "cdglnehniifkbagbbombnjghhcihifij"
      "dpaefegpjhgeplnkomgbcmmlffkijbgp"
      "alblebhaoakdgapamjdifdfnaicpnklm"
      "idhdcccjlcijifdphaicgnmhifpmilge"
      "ghmbeldphafepmbegfdlkpapadhbakde"
      "jplgfhpmjnbigmhklmmbgecoobifkmpa"
      "cbghhgpcnddeihccjmnadmkaejncjndb"
      "fcoeoabgfenejglbffodgkkbkcdhcgfn"
      "lahhiofdgnbcgmemekkmjnpifojdaelb"
      "icgdjligmnkgafcejnjbdjgpeajefaom"
      "fcalilbnpkfikdppppppchmkdipibalb"
    ];
  };
}
