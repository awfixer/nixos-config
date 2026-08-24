import { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "@playwright/test";

const currentDir = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
	testDir: "./tests",
	timeout: 30_000,
	use: {
		baseURL: "http://127.0.0.1:4173",
		headless: true,
	},
	webServer: {
		command: "npm run dev -- --host 127.0.0.1 --port 4173",
		cwd: currentDir,
		url: "http://127.0.0.1:4173",
		reuseExistingServer: !process.env.CI,
	},
});
