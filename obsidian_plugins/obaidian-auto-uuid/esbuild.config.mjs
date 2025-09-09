import { build } from "esbuild";

const external = [
    "obsidian",
    "electron",
    "@codemirror/state",
    "@codemirror/view",
    "@codemirror/language"
];

await build({
    entryPoints: ["main.ts"],
    outfile: "main.js",
    bundle: true,
    platform: "node",
    format: "cjs",
    target: "es2020",
    external,
    sourcemap: true,
});

console.log("[esbuild] build complete");