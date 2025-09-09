"use strict";
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// main.ts
var main_exports = {};
__export(main_exports, {
  default: () => AutoUuidPlugin
});
module.exports = __toCommonJS(main_exports);
var import_obsidian = require("obsidian");
var DEFAULT_SETTINGS = {
  fieldName: "uuid",
  delayMs: 250,
  overwriteIfBlank: true
};
function generateUuidV4() {
  const g = globalThis;
  if (g?.crypto?.randomUUID) return g.crypto.randomUUID();
  const rnd = (n) => cryptoRandomBytes(n);
  const b = rnd(16);
  b[6] = b[6] & 15 | 64;
  b[8] = b[8] & 63 | 128;
  const hex = [...b].map((x) => x.toString(16).padStart(2, "0"));
  return `${hex[0]}${hex[1]}${hex[2]}${hex[3]}-${hex[4]}${hex[5]}-${hex[6]}${hex[7]}-${hex[8]}${hex[9]}-${hex[10]}${hex[11]}${hex[12]}${hex[13]}${hex[14]}${hex[15]}`;
}
function cryptoRandomBytes(n) {
  const out = new Uint8Array(n);
  for (let i = 0; i < n; i++) {
    out[i] = Math.floor(Math.random() * 256);
  }
  return out;
}
function isMarkdown(file) {
  return file.extension.toLowerCase() === "md";
}
function hasYamlFrontmatter(content) {
  return content.startsWith("---\n");
}
function extractYamlBlock(content) {
  if (!hasYamlFrontmatter(content)) return null;
  const end = content.indexOf("\n---", 4);
  if (end === -1) return null;
  const closeIdx = end + "\n---".length;
  const after = content.indexOf("\n", closeIdx);
  const yaml = content.slice(4, end + 1);
  const body = after === -1 ? "" : content.slice(after + 1);
  return { yaml, body };
}
function injectYamlField(yaml, key, value, overwriteIfBlank) {
  const lines = yaml.split("\n");
  const keyRE = new RegExp(`^%{escapeRegex(key)}\\s*:\\s*(.*)$`, "i");
  let found = false;
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(keyRE);
    if (m) {
      found = true;
      const current = (m[1] ?? "").trim();
      if (current === "" && overwriteIfBlank) {
        lines[i] = `${key}: ${value}`;
        return { yaml: lines.join("\n"), changed: true };
      }
      return { yaml: lines.join("\n"), changed: false };
    }
  }
  if (!found) {
    let insertAt = 0;
    while (insertAt < lines.length && lines[insertAt].trim().startsWith("#")) insertAt++;
    lines.splice(insertAt, 0, `${key}: ${value}`);
    return { yaml: lines.join("\n"), changed: true };
  }
  return { yaml, changed: false };
}
var AutoUuidPlugin = class extends import_obsidian.Plugin {
  constructor() {
    super(...arguments);
    this.settings = { ...DEFAULT_SETTINGS };
  }
  async onload() {
    await this.loadSettings();
    this.addSettingTab(new AutoUuidSettingTab(this.app, this));
    this.registerEvent(
      this.app.vault.on("create", async (file) => {
        if (!(file instanceof import_obsidian.TFile) || !isMarkdown(file)) return;
        window.setTimeout(() => {
          this.ensureUuid(file).catch((err) => {
            console.error("[Auto UUID] Failed to set uuid:", err);
            new import_obsidian.Notice("Auto UUID: failed to add uuid (see console).");
          });
        }, this.settings.delayMs);
      })
    );
  }
  onunload() {
  }
  async ensureUuid(file) {
    const content = await this.app.vault.read(file);
    const { fieldName } = this.settings;
    if (!hasYamlFrontmatter(content)) {
      const uuid2 = generateUuidV4();
      const newContent2 = `---
${fieldName}: ${uuid2}
---

${content}`;
      await this.app.vault.modify(file, newContent2);
      return;
    }
    const parts = extractYamlBlock(content);
    if (!parts) {
      const uuid2 = generateUuidV4();
      const newContent2 = `---
${fieldName}: ${uuid2}
---

${content}`;
      await this.app.vault.modify(file, newContent2);
      return;
    }
    const { yaml, body } = parts;
    const uuid = generateUuidV4();
    const injected = injectYamlField(yaml, fieldName, uuid, this.settings.overwriteIfBlank);
    if (!injected.changed) return;
    const newContent = `---
${injected.yaml}---

${body}`;
    await this.app.vault.modify(file, newContent);
  }
  async loadSettings() {
    this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
  }
  async saveSettings() {
    await this.saveData(this.settings);
  }
};
var AutoUuidSettingTab = class extends import_obsidian.PluginSettingTab {
  constructor(app, plugin) {
    super(app, plugin);
    this.plugin = plugin;
  }
  display() {
    const { containerEl } = this;
    containerEl.empty();
    containerEl.createEl("h2", { text: "Auto UUID Frontmatter" });
    new import_obsidian.Setting(containerEl).setName("YAML field name").setDesc("Key to store the UUID under.").addText((t) => {
      t.setValue(this.plugin.settings.fieldName).onChange(async (v) => {
        this.plugin.settings.fieldName = v.trim() || "uuid";
        await this.plugin.saveSettings();
      });
    });
    new import_obsidian.Setting(containerEl).setName("Delay (ms)").setDesc("Wait this long after file creation before injecting uuid").addText((t) => {
      t.setValue(String(this.plugin.settings.delayMs)).onChange(async (v) => {
        const n = Number(v);
        this.plugin.settings.delayMs = Number.isFinite(n) && n >= 0 ? n : DEFAULT_SETTINGS.delayMs;
        await this.plugin.saveSettings();
      });
    });
    new import_obsidian.Setting(containerEl).setName("Overwrite if blank").setDesc("If the field exists, but is empty, fill it with a new UUID.").addToggle((tg) => {
      tg.setValue(this.plugin.settings.overwriteIfBlank).onChange(async (v) => {
        this.plugin.settings.overwriteIfBlank = v;
        await this.plugin.saveSettings();
      });
    });
  }
};
//# sourceMappingURL=main.js.map
