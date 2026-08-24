{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.cline;

  # Cline CLI MCP servers. Cline reads ~/.cline/mcp.json (see docs.cline.bot/mcp).
  # Mirrors .mcp.json in the repo root, converted to Cline's config format:
  # remote HTTP servers use "type": "streamableHttp" (omitting it would default
  # to legacy SSE), and there is no "lifecycle" key.
  defaultMcpServers = {
    context7 = {
      type = "streamableHttp";
      url = "https://mcp.context7.com/mcp/oauth";
      disabled = false;
      autoApprove = [ ];
    };
    nixos = {
      command = "uvx";
      args = [ "mcp-nixos" ];
      disabled = false;
      autoApprove = [ ];
    };
  };

  clinePackage = pkgs.callPackage ../packages/ai-daemon { };
in
{
  options.programs.cline = {
    enable = lib.mkEnableOption "the Cline AI coding agent CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = clinePackage;
      defaultText = lib.literalExpression "pkgs.callPackage ../packages/ai-daemon { }";
      description = ''
        The Cline CLI package. Built with a bundled Bun runtime, so it needs
        neither node nor bun from the system PATH.
      '';
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = defaultMcpServers;
      defaultText = lib.literalExpression "defaultMcpServers";
      description = ''
        MCP server configuration written to ~/.cline/mcp.json. Server commands
        (e.g. uvx) are resolved from your PATH at runtime by Cline. Set to
        `{ }` to stop managing that file.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];
    })
    (lib.mkIf (cfg.enable && cfg.mcpServers != { }) {
      home.file.".cline/mcp.json".text = builtins.toJSON {
        mcpServers = cfg.mcpServers;
      };
    })
  ];
}
