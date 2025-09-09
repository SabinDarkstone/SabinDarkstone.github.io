import {
    App,
    Notice,
    Plugin,
    PluginSettingTab,
    Setting,
    TFile
} from "obsidian";

interface AutoUuidSettings {
    fieldName: string;
    delayMs: number;
    overwriteIfBlank: boolean;
}

const DEFAULT_SETTINGS: AutoUuidSettings = {
    fieldName: "uuid",
    delayMs: 250,
    overwriteIfBlank: true
};

function generateUuidV4(): string {
    // Prefer native crypto.randomUUID if available
    const g = (globalThis as any);
    if (g?.crypto?.randomUUID) return g.crypto.randomUUID();

    // Fallback RFC4122 v4
    const rnd = (n: number) => (cryptoRandomBytes(n));
    const b = rnd(16);
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    const hex = [...b].map((x) => x.toString(16).padStart(2, "0"));
    return `${hex[0]}${hex[1]}${hex[2]}${hex[3]}-${hex[4]}${hex[5]}-${hex[6]}${hex[7]}-${hex[8]}${hex[9]}-${hex[10]}${hex[11]}${hex[12]}${hex[13]}${hex[14]}${hex[15]}`;
}

function cryptoRandomBytes(n: number): Uint8Array {
    const out = new Uint8Array(n);
    for (let i = 0; i < n; i++) {
        out[i] = Math.floor(Math.random() * 256);
    }
    return out;
}

function isMarkdown(file: TFile): boolean {
    return file.extension.toLowerCase() === "md";
}

function hasYamlFrontmatter(content: string): boolean {
    return content.startsWith("---\n");
}

function extractYamlBlock(content: string): { yaml: string; body: string } | null {
    if (!hasYamlFrontmatter(content)) return null;
    const end = content.indexOf("\n---", 4);
    if (end === -1) return null;

    const closeIdx = end + "\n---".length;
    const after = content.indexOf("\n", closeIdx);
    const yaml = content.slice(4, end + 1);
    const body = after === -1 ? "" : content.slice(after + 1);
    return { yaml, body };
}

function injectYamlField(yaml: string, key: string, value: string, overwriteIfBlank: boolean): { yaml: string; changed: boolean } {
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

function escapeRegex(s: string) {
    return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}


export default class AutoUuidPlugin extends Plugin {
    settings: AutoUuidSettings = { ...DEFAULT_SETTINGS };

    async onload() {
        await this.loadSettings();

        this.addSettingTab(new AutoUuidSettingTab(this.app, this));

        this.registerEvent(
            this.app.vault.on("create", async (file) => {
                if (!(file instanceof TFile) || !isMarkdown(file)) return;

                window.setTimeout(() => {
                    this.ensureUuid(file). catch((err) => {
                        console.error("[Auto UUID] Failed to set uuid:", err);
                        new Notice("Auto UUID: failed to add uuid (see console).");
                    });
                }, this.settings.delayMs);
            })
        );
    }

    onunload() {

    }

    private async ensureUuid(file: TFile) {
        const content = await this.app.vault.read(file);
        const { fieldName } = this.settings;

        if (!hasYamlFrontmatter(content)) {
            const uuid = generateUuidV4();
            const newContent = `---\n${fieldName}: ${uuid}\n---\n\n${content}`;
            await this.app.vault.modify(file, newContent);
            return;
        }

        const parts = extractYamlBlock(content);
        if (!parts) {
            const uuid = generateUuidV4();
            const newContent = `---\n${fieldName}: ${uuid}\n---\n\n${content}`;
            await this.app.vault.modify(file, newContent);
            return;
        }

        const { yaml, body } = parts;
        const uuid = generateUuidV4();
        const injected = injectYamlField(yaml, fieldName, uuid, this.settings.overwriteIfBlank);

        if (!injected.changed) return;

        const newContent = `---\n${injected.yaml}---\n\n${body}`;
        await this.app.vault.modify(file, newContent);
    }

    async loadSettings() {
        this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
    }

    async saveSettings() {
        await this.saveData(this.settings);
    }
}

class AutoUuidSettingTab extends PluginSettingTab {
    plugin: AutoUuidPlugin;

    constructor(app: App, plugin: AutoUuidPlugin) {
        super(app, plugin);
        this.plugin = plugin;
    }

    display(): void {
        const { containerEl } = this;
        containerEl.empty();

        containerEl.createEl("h2", { text: "Auto UUID Frontmatter" });

        new Setting(containerEl)
            .setName("YAML field name")
            .setDesc("Key to store the UUID under.")
            .addText((t) => {
                t
                    .setValue(this.plugin.settings.fieldName)
                    .onChange(async (v) => {
                        this.plugin.settings.fieldName = v.trim() || "uuid";
                        await this.plugin.saveSettings();
                    })
            });

        new Setting(containerEl)
            .setName("Delay (ms)")
            .setDesc("Wait this long after file creation before injecting uuid")
            .addText((t) => {
                t.setValue(String(this.plugin.settings.delayMs)).onChange(async (v) => {
                    const n = Number(v);
                    this.plugin.settings.delayMs = Number.isFinite(n) && n >= 0 ? n : DEFAULT_SETTINGS.delayMs;
                    await this.plugin.saveSettings();
                })
            });

        new Setting(containerEl)
            .setName("Overwrite if blank")
            .setDesc("If the field exists, but is empty, fill it with a new UUID.")
            .addToggle((tg) => {
                tg.setValue(this.plugin.settings.overwriteIfBlank).onChange(async (v) => {
                    this.plugin.settings.overwriteIfBlank = v;
                    await this.plugin.saveSettings();
                })
            });
    }
}