const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');

const VIDEOS_DIR = path.join(__dirname, '..', 'videos');

const SAMPLE_VIDEOS = [
  'BigBuckBunny.mp4',
  'ForBiggerBlazes.mp4',
  'ForBiggerEscapes.mp4',
  'ForBiggerFun.mp4',
  'ForBiggerJoyrides.mp4',
  'ForBiggerMeltdowns.mp4',
  'ElephantsDream.mp4',
  'SubaruOutbackOnStreetAndDirt.mp4',
  'TearsOfSteel.mp4',
];

const BASE_URL = 'https://storage.googleapis.com/gtv-videos-bucket/sample';

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    const protocol = url.startsWith('https') ? https : http;

    protocol.get(url, (response) => {
      // Handle redirects
      if (response.statusCode >= 300 && response.statusCode < 400 && response.headers.location) {
        file.close();
        fs.unlinkSync(dest);
        return downloadFile(response.headers.location, dest).then(resolve).catch(reject);
      }

      if (response.statusCode !== 200) {
        file.close();
        fs.unlinkSync(dest);
        return reject(new Error(`HTTP ${response.statusCode} for ${url}`));
      }

      const total = parseInt(response.headers['content-length'], 10);
      let downloaded = 0;
      let lastLog = 0;

      response.on('data', (chunk) => {
        downloaded += chunk.length;
        const pct = total ? Math.round((downloaded / total) * 100) : 0;
        if (pct - lastLog >= 10 || pct === 100) {
          lastLog = pct;
          process.stdout.write(`\r  ${path.basename(dest)}: ${pct}%`);
        }
      });

      response.pipe(file);

      file.on('finish', () => {
        process.stdout.write(`\r  ${path.basename(dest)}: 100% - done\n`);
        file.close();
        resolve();
      });
    }).on('error', (err) => {
      file.close();
      fs.unlinkSync(dest);
      reject(err);
    });
  });
}

async function main() {
  if (!fs.existsSync(VIDEOS_DIR)) {
    fs.mkdirSync(VIDEOS_DIR, { recursive: true });
  }

  console.log('Downloading sample videos...\n');

  for (const filename of SAMPLE_VIDEOS) {
    const dest = path.join(VIDEOS_DIR, filename);
    if (fs.existsSync(dest) && fs.statSync(dest).size > 0) {
      console.log(`  ${filename} already exists, skipping`);
      continue;
    }
    const url = `${BASE_URL}/${filename}`;
    try {
      await downloadFile(url, dest);
    } catch (err) {
      console.error(`\n  Failed to download ${filename}: ${err.message}`);
    }
  }

  // Show results
  console.log('\nDownloaded videos:');
  const files = fs.readdirSync(VIDEOS_DIR).filter(f => f.endsWith('.mp4'));
  for (const f of files) {
    const size = fs.statSync(path.join(VIDEOS_DIR, f)).size;
    console.log(`  ${f} - ${(size / 1024 / 1024).toFixed(1)} MB`);
  }
  console.log(`\nTotal: ${files.length} videos`);
}

main().catch(console.error);
