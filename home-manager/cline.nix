{ pkgs, ... }:

# Cline CLI MCP servers. Cline reads ~/.cline/mcp.json (see docs.cline.bot/mcp).
# Mirrors .mcp.json in the repo root, converted to Cline's config format:
# remote HTTP servers use "type": "streamableHttp" (omitting it would default
# to legacy SSE), and there is no "lifecycle" key.
{
  home.file.".cline/mcp.json".text = builtins.toJSON {
    mcpServers = {
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
  };
}
