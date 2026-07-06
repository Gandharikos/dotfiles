import { defineConfig } from "astro/config"
import starlight from "@astrojs/starlight"

export default defineConfig({
  publicDir: "../.assets",
  site: process.env.DOCS_SITE ?? "https://gandharikos.github.io/dotfiles",
  base: process.env.DOCS_BASE ?? "/",
  integrations: [
    starlight({
      title: "dotfiles",
      description: "Personal NixOS, nix-darwin, and Home Manager configuration.",
      favicon: "/nixos_logo.png",
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/Gandharikos/dotfiles",
        },
      ],
      customCss: ["./src/styles/custom.css"],
      sidebar: [
        {
          label: "Start Here",
          items: [
            { label: "Getting Started", slug: "getting-started" },
            { label: "Architecture", slug: "architecture" },
            { label: "Desktop", slug: "desktop" },
          ],
        },
        {
          label: "Operations",
          items: [
            { label: "Secrets", slug: "operations/secrets" },
            { label: "Deployment", slug: "operations/deployment" },
            { label: "Disko", slug: "operations/disko" },
          ],
        },
        {
          label: "Reference",
          items: [
            { label: "SSH", slug: "reference/ssh" },
            { label: "Mihomo", slug: "reference/mihomo" },
            { label: "YubiKey", slug: "reference/yubikey" },
          ],
        },
      ],
    }),
  ],
})
