# AI and Machine Learning Tools
# Tools for AI development, local LLM inference, and AI-powered CLI applications
# AI tools overview: https://github.com/steven2358/awesome-generative-ai
{ pkgs, ... }:

let
  # AI and machine learning development tools
  ai = with pkgs; [
    # Local LLM Inference
    ollama # Run large language models locally - https://ollama.ai/

    # AI-powered CLI Tools
    gemini-cli # Google Gemini AI CLI - https://github.com/reacherhq/gemini-cli
    codex # AI-powered code generation - https://openai.com/blog/openai-codex/
    claude-code # Claude AI code assistant - https://claude.ai/code
  ];
in

{
  # Install all AI packages to user environment
  home.packages = builtins.concatLists [ ai ];
}
