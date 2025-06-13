import { get } from "https"; // or 'https' for https:// URLs
import { createWriteStream } from "fs";

async function getFiles() {
  const apiUrl =
    "https://api.github.com/repos/wowdev/wow-listfile/releases/latest";

  const headers = {
    headers: {
      "User-Agent": "WoW Group Music Addon",
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
    const item = soundFiles[i];
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

const soundFiles = await getFiles();

console.log("Writing files to assets folder");
for (let i = 0; i < soundFiles.length; i++) {
  //creature is specia, it has 3 files because 1 file is too large for wow, and wow starts hitting us with a stick if we include it
  if (fileNames[i] === "creature") {
    const idFilestream = createWriteStream(`assets/${fileNames[i]}index.lua`);
    idFilestream.write(`
    local _, core = ...;
    core.${fileNames[i]}Index = {
        ${soundFiles[i].map((item) => ` "${item.id}"`).join(",\n ")}
    }`);
    const pathFilestream = createWriteStream(`assets/${fileNames[i]}path.lua`);
    pathFilestream.write(`
    local _, core = ...;
    core.${fileNames[i]}Path = {
        ${soundFiles[i]
          .map((item) => `"${item.path.replace(/(\r\n|\n|\r)/gm, "")}"`)
          .join(",\n ")}
    }`);
    const nameFilestream = createWriteStream(`assets/${fileNames[i]}name.lua`);
    nameFilestream.write(`
    local _, core = ...;
    core.${fileNames[i]}Name = {
        ${soundFiles[i]
          .map((item) => `"${item.name.replace(/(\r\n|\n|\r)/gm, "")}"`)
          .join(",\n ")}
    }`);
  } else {
    const fileStream = createWriteStream(`assets/${fileNames[i]}data.lua`);
    fileStream.write(`
    local _, core = ...;
    core.${fileNames[i]} = {
        ${soundFiles[i]
          .map(
            (item) =>
              ` { id = "${item.id}", path = "${item.path.replace(
                /(\r\n|\n|\r)/gm,
                ""
              )}", name = "${item.name.replace(/(\r\n|\n|\r)/gm, "")}" }`
          )
          .join(",\n ")}
    }`);
  }
}
