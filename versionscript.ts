import { execFile } from "child_process";
import { mkdir, readFile, writeFile } from "fs/promises";
import { promisify } from "util";
import { join, resolve } from "path";

interface SoundFile {
    id: string;
    name: string;
    path: string;
}

interface Asset {
    name: string;
    browser_download_url: string;
}

interface ProductConfig {
    name: string;
    basedir: string;
    output: string;
}

const run = promisify(execFile);
const root = resolve(import.meta.dirname);
const dumpDirectory = join(root, "tools", "cascdump");
const dumpProject = join(dumpDirectory, "ShortwaveCascDump.csproj");

async function ensureDumper(): Promise<void> {
    console.log("Building local CASC dumper");
    await run("dotnet", ["build", dumpProject, "--configuration", "Release", "--nologo"], {
        cwd: root,
        windowsHide: true,
    });
}

async function dumpProduct(product: ProductConfig): Promise<Set<string>> {
    const output = join(root, "tools", "cascdump", `${product.name}-ids.txt`);
    console.log(`Reading ${product.name} client metadata from ${product.basedir}`);

    await run(
        "dotnet",
        [
            "run",
            "--project",
            dumpProject,
            "--configuration",
            "Release",
            "--no-build",
            "--",
            "--basedir",
            product.basedir,
            "--product",
            product.name,
            "--output",
            output,
        ],
        { cwd: root, windowsHide: true, maxBuffer: 1024 * 1024 * 8 },
    );

    const ids = (await readFile(output, "utf8"))
        .split(/\r?\n/)
        .map((id) => id.trim())
        .filter(Boolean);
    return new Set(ids);
}

async function getListfile(): Promise<Map<string, string>> {
    const apiUrl = "https://api.github.com/repos/wowdev/wow-listfile/releases/latest";
    const headers = { "User-Agent": "WoW Shortwave Addon" };
    console.log("Finding latest listfile from GitHub");

    const releaseResponse = await fetch(apiUrl, { headers });
    if (!releaseResponse.ok)
        throw new Error(`GitHub release request failed: ${releaseResponse.status}`);

    const release = (await releaseResponse.json()) as { assets?: Asset[] };
    const asset = release.assets?.find((candidate) =>
        candidate.name === "community-listfile-withcapitals.csv",
    );
    if (!asset)
        throw new Error("The latest release did not contain community-listfile-withcapitals.csv.");

    console.log("Downloading listfile");
    const fileResponse = await fetch(asset.browser_download_url, { headers });
    if (!fileResponse.ok)
        throw new Error(`Listfile download failed: ${fileResponse.status}`);

    const result = new Map<string, string>();
    for (const line of (await fileResponse.text()).split(/\r?\n/)) {
        const separator = line.indexOf(";");
        if (separator < 1)
            continue;

        const id = line.slice(0, separator).trim();
        const path = line.slice(separator + 1).trim();
        if (/^\d+$/.test(id) && path)
            result.set(id, path);
    }
    return result;
}

function parseSoundFiles(listfile: Map<string, string>, ids: Set<string>): SoundFile[] {
    const files: SoundFile[] = [];
    for (const [id, originalPath] of listfile) {
        if (!ids.has(id))
            continue;

        const path = originalPath.replace(/\.(mp3|ogg)$/i, "");
        const filename = path.split("/").pop() ?? "";
        if (!/\.(mp3|ogg)$/i.test(originalPath) || /\.meta$/i.test(originalPath))
            continue;

        files.push({
            id,
            path,
            name: filename.replace(/\.(mp3|ogg)$/i, ""),
        });
    }
    return files;
}

function luaString(value: string): string {
    return JSON.stringify(value);
}

async function writeLuaFiles(product: ProductConfig, listfile: Map<string, string>, ids: Set<string>): Promise<void> {
    const soundFiles = parseSoundFiles(listfile, ids);
    const categories: Record<string, SoundFile[]> = {
        music: [],
        ambience: [],
        creature: [],
        spells: [],
        character: [],
        other: [],
    };

    for (const file of soundFiles) {
        const path = file.path.toLowerCase();
        const category = path.includes("sound/music")
            ? "music"
            : path.includes("sound/ambience")
                ? "ambience"
                : path.includes("sound/creature")
                    ? "creature"
                    : path.includes("sound/spell")
                        ? "spells"
                        : path.includes("sound/character")
                            ? "character"
                            : "other";
        categories[category].push(file);
    }

    const suffix = product.name === "wow" ? "retail" : "forever";
    const folders: Record<string, string> = {
        music: "ShortWave_MusicData",
        ambience: "ShortWave_AmbienceData",
        creature: "ShortWave_SFXData",
        spells: "ShortWave_SFXData",
        character: "ShortWave_SFXData",
        other: "ShortWave_SFXData",
    };

    for (const [category, files] of Object.entries(categories)) {
        const directory = join(root, folders[category]);
        await mkdir(directory, { recursive: true });

        if (category === "creature") {
            const creatureFiles = [
                ["index", files.map((_, index) => index + 1)],
                ["id", files.map((file) => file.id)],
                ["path", files.map((file) => file.path)],
                ["name", files.map((file) => file.name)],
            ] as const;

            for (const [part, values] of creatureFiles) {
                const output = join(directory, `${category}${part}_${suffix}.lua`);
                const body = values
                    .map((value) => ` ${typeof value === "number" ? value : luaString(value)}`)
                    .join(",\n");
                const globalName = part === "index" ? "creature" : `creature${part[0].toUpperCase()}${part.slice(1)}`;
                await writeFile(output, `ShortWaveGlobalData.${globalName} = {\n${body}\n}\n`, "utf8");
            }
        } else {
            const output = join(directory, `${category}data_${suffix}.lua`);
            const body = files
                .map((file) => ` { id = ${luaString(file.id)}, path = ${luaString(file.path)}, name = ${luaString(file.name)} }`)
                .join(",\n");
            await writeFile(output, `ShortWaveGlobalData.${category} = {\n${body}\n}\n`, "utf8");
        }
    }

    const summaryPath = join(root, "tools", "cascdump", `${suffix}-sounds.json`);
    await writeFile(summaryPath, JSON.stringify(soundFiles, null, 2) + "\n", "utf8");
    console.log(`Wrote ${soundFiles.length} ${suffix} sound entries`);
}

const installationDirectory = "C:\\Program Files (x86)\\World of Warcraft";
const retailDirectory = process.env.SHORTWAVE_RETAIL_DIR ?? installationDirectory;
const foreverDirectory = process.env.SHORTWAVE_FOREVER_DIR ?? installationDirectory;
const retailProduct = process.env.SHORTWAVE_RETAIL_PRODUCT ?? "wow";
const foreverProduct = process.env.SHORTWAVE_FOREVER_PRODUCT ?? "wow_classic_beta";
if (!retailDirectory || !foreverDirectory) {
    throw new Error(
        "Set SHORTWAVE_RETAIL_DIR and SHORTWAVE_FOREVER_DIR to the WoW installation root containing .build.info.",
    );
}

await ensureDumper();
const listfile = await getListfile();
const [retailIds, foreverIds] = await Promise.all([
    dumpProduct({ name: retailProduct, basedir: retailDirectory, output: "retail" }),
    dumpProduct({ name: foreverProduct, basedir: foreverDirectory, output: "forever" }),
]);

await writeLuaFiles({ name: retailProduct, basedir: retailDirectory, output: "retail" }, listfile, retailIds);
await writeLuaFiles({ name: foreverProduct, basedir: foreverDirectory, output: "forever" }, listfile, foreverIds);
console.log("Finished version-specific sound generation");