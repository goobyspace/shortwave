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
    return item.name.includes(".ogg") || item.name.includes(".mp3");
  });

  const music = [];
  const ambience = [];
  const otherSounds = [];
  for (let i = 0; i < soundFiles.length; i++) {
    const item = soundFiles[i];
    if (item.path.toLowerCase().includes("sound/music")) {
      music.push(item);
    } else if (item.path.toLowerCase().includes("sound/ambience")) {
      ambience.push(item);
    } else {
      otherSounds.push(item);
    }
  }
  return [music, ambience, otherSounds];
}

// we currently don't use otherSounds, since it's really fucking big, but we might in the future
const [music, ambience, otherSounds] = await getFiles();

console.log("Writing listfile to musicdata.lua");
const musicFile = createWriteStream("assets/musicdata.lua");
musicFile.write(`
local _, core = ...;
core.music = {
    ${music
      .map(
        (item) =>
          ` { id = "${item.id}", path = "${item.path.replace(
            /(\r\n|\n|\r)/gm,
            ""
          )}", name = "${item.name.replace(/(\r\n|\n|\r)/gm, "")}" }`
      )
      .join(",\n ")}
}`);

console.log("Writing listfile to ambiencedata.lua");
const ambienceFile = createWriteStream("assets/ambiencedata.lua");
ambienceFile.write(`
local _, core = ...;
core.ambience = {
    ${ambience
      .map(
        (item) =>
          ` { id = "${item.id}", path = "${item.path.replace(
            /(\r\n|\n|\r)/gm,
            ""
          )}", name = "${item.name.replace(/(\r\n|\n|\r)/gm, "")}" }`
      )
      .join(",\n ")}
}`);

console.log("Writing listfile to sfxdata.lua");
const othersoundsFile = createWriteStream("assets/sfxdata.lua");
othersoundsFile.write(`
local _, core = ...;
core.sfx = {
    ${otherSounds
      .map(
        (item) =>
          ` { id = "${item.id}", path = "${item.path.replace(
            /(\r\n|\n|\r)/gm,
            ""
          )}", name = "${item.name.replace(/(\r\n|\n|\r)/gm, "")}" }`
      )
      .join(",\n ")}
}`);
