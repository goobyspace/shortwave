import { get } from "https"; // or 'https' for https:// URLs
import { createWriteStream } from "fs";

async function getFiles() {
  const apiUrl =
    "https://api.github.com/repos/wowdev/wow-listfile/releases/latest";

  const headers = {
    headers: {
      "User-Agent": "WoW Shortwave Addon",
    },
  };
  console.log("Finding latest listfile from GitHub");
  const request = await fetch(apiUrl, headers);

  const data = await request.json();

  if (!data.assets || data.assets.length === 0) {
    console.error("No assets found in the latest release.");
    process.exit(1);
  }

  const listFileUrl = data.assets.find((asset) =>
    asset.name.includes("community-listfile-withcapitals")
  ).browser_download_url;

  console.log("Downloading listfile");
  const fileRequest = await fetch(listFileUrl, headers);
  const listfile = await fileRequest.text();

  console.log("Parsing listfile (This may take a while)");
  const parsedFile = listfile.split("\n").map((line) => {
    const [id, path] = line.split(";");
    if (!id || !path) {
      console.log("No path or ID found for line: ", line);
      return null; // Skip invalid lines
    }
    const name = path.split("/").pop();
    return { id, path, name };
  });

  const soundFiles = parsedFile.filter((item) => {
    if (!item || !item.id || !item.path || !item.name) {
      console.log("No path or ID found for item: ", item);
      return false;
    }
    if (item.name.includes(".meta")) return false; //sometimes files have names like .mp3.meta
    return item.name.includes(".ogg") || item.name.includes(".mp3");
  });

  const music = [];
  const ambience = [];
  const creature = [];
  const spells = [];
  const character = [];
  const other = [];
  for (let i = 0; i < soundFiles.length; i++) {
    const item = {
      id: soundFiles[i].id,
      name: soundFiles[i].name.replace(/(\r\n|\n|\r|.mp3|.ogg)/gm, ""),
      path: soundFiles[i].path.replace(/(\r\n|\n|\r|.mp3|.ogg)/gm, ""),
    };
    const path = item.path.toLowerCase();
    if (path.includes("sound/music")) {
      music.push(item);
    } else if (path.includes("sound/ambience")) {
      ambience.push(item);
    } else if (path.includes("sound/creature")) {
      creature.push(item);
    } else if (path.includes("sound/spell")) {
      spells.push(item);
    } else if (path.includes("sound/character")) {
      character.push(item);
    } else {
      other.push(item);
    }
  }

  return [music, ambience, creature, spells, character, other];
}

const fileNames = [
  "music",
  "ambience",
  "creature",
  "spells",
  "character",
  "other",
];

const folder = [
  "ShortWave_MusicData",
  "ShortWave_AmbienceData",
  "ShortWave_SFXData",
  "ShortWave_SFXData",
  "ShortWave_SFXData",
  "ShortWave_SFXData",
];

const soundFiles = await getFiles();

console.log("Writing files to assets folder");
for (let i = 0; i < soundFiles.length; i++) {
  //creature is special, it has 4 files because 1 file is too large for wow, and wow starts hitting us with a stick if we include it
  if (fileNames[i] === "creature") {
    const indexFilestream = createWriteStream(
      `${folder[i]}/${fileNames[i]}index.lua`
    );
    indexFilestream.write(`
ShortWaveGlobalData.${fileNames[i]} = {
        ${soundFiles[i].map((_, index) => ` ${index + 1}`).join(",\n ")}
    }`);

    const idFilestream = createWriteStream(
      `${folder[i]}/${fileNames[i]}id.lua`
    );
    idFilestream.write(`
ShortWaveGlobalData.${fileNames[i]}Id = {
        ${soundFiles[i].map((item) => ` "${item.id}"`).join(",\n ")}
    }`);

    const pathFilestream = createWriteStream(
      `${folder[i]}/${fileNames[i]}path.lua`
    );
    pathFilestream.write(`
ShortWaveGlobalData.${fileNames[i]}Path = {
        ${soundFiles[i].map((item) => `"${item.path}"`).join(",\n ")}
    }`);

    const nameFilestream = createWriteStream(
      `${folder[i]}/${fileNames[i]}name.lua`
    );
    nameFilestream.write(`
ShortWaveGlobalData.${fileNames[i]}Name = {
        ${soundFiles[i].map((item) => `"${item.name}"`).join(",\n ")}
    }`);
  } else {
    const fileStream = createWriteStream(
      `${folder[i]}/${fileNames[i]}data.lua`
    );
    fileStream.write(`
ShortWaveGlobalData.${fileNames[i]} = {
        ${soundFiles[i]
          .map(
            (item) =>
              ` { id = "${item.id}", path = "${item.path}", name = "${item.name}" }`
          )
          .join(",\n ")}
    }`);
  }
}
