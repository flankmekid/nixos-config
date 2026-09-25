# ── Local AI: Ollama on the RTX 5060 (8 GB GDDR7, ~384 GB/s) ──────────────────
#
# Token generation is memory-bandwidth bound, so the rule of thumb is
#   tok/s ≈ 384 GB/s × ~0.65 ÷ model size in GB
# and anything that spills out of the 8 GB of VRAM into system RAM gets
# 3-5× slower. With 8 GB of VRAM that makes the sweet spots:
#
#   qwen3:8b  (Q4_K_M, ~5 GB)   ~45-55 tok/s   best quality that fully fits
#   qwen3.5:4b (Q4_K_M, ~3.4 GB) main model for Hermes Agent: 262k native
#              context and hybrid attention (only 1 in 4 layers keeps a KV
#              cache), so a 64k window costs ~1 GB and stays 100% on GPU.
#              Hermes refuses models under 64k; qwen3:8b tops out at 40k.
#
# Usage:
#   ollama run qwen3:8b --verbose     # --verbose prints the real eval rate
#   ollama ps                         # shows "100% GPU" if it fits in VRAM
#   curl localhost:11434/api/tags     # REST API; OpenAI-compatible at /v1
#
# PRIME offload: CUDA doesn't need `nvidia-offload`; the 5060 wakes up when
# a model is loaded and powers back down after OLLAMA_KEEP_ALIVE expires.
# Plug in first: on battery the GPU sits near its 45 W floor and is slower.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.ollama = {
    enable = true;
    # CUDA build. nixpkgs targets sm_120 (Blackwell) by default. Do NOT set
    # nixpkgs.config.cudaSupport globally instead: that would rebuild half
    # the system (blender, opencv, …) from source.
    package = pkgs.ollama-cuda;

    # Listens on 127.0.0.1:11434 only; the firewall stays closed.

    environmentVariables = {
      # Flash attention: less VRAM per token of context, a bit faster.
      OLLAMA_FLASH_ATTENTION = "1";
      # 8-bit KV cache: halves context memory with no noticeable quality loss.
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      # Hermes Agent's minimum. qwen3.5:4b at 64k is ~4.6 GB, 100% GPU.
      # Models with a smaller native limit (qwen3:8b: 40k) get clamped to it.
      OLLAMA_CONTEXT_LENGTH = "65536";
      # Only one model in VRAM at a time; two 8B models will not fit.
      OLLAMA_MAX_LOADED_MODELS = "1";
      # Unload after 5 idle minutes so the dGPU can power down again.
      OLLAMA_KEEP_ALIVE = "5m";
    };

    # Pulled in the background by ollama-model-loader.service after a
    # rebuild (~7.5 GB total). Remove a line to stop tracking it; set
    # syncModels = true to also delete models not listed here.
    loadModels = [
      "qwen3.5:4b"
      "qwen3:8b"
    ];
  };

  # The NixOS CUDA team's binary cache. CUDA packages are unfree, so
  # cache.nixos.org doesn't build them; without this, ollama-cuda compiles
  # from source for hours.
  nix.settings = {
    substituters = [ "https://cache.nixos-cuda.org" ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };
}
