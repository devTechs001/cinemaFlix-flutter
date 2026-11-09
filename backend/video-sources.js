// Working public sample video URLs (legacy Google bucket returns 403).
const VIDEO_CDN_MAP = {
  'BigBuckBunny.mp4': 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4',
  'ForBiggerBlazes.mp4': 'https://download.samplelib.com/mp4/sample-5s.mp4',
  'ForBiggerEscapes.mp4': 'https://download.samplelib.com/mp4/sample-10s.mp4',
  'ForBiggerFun.mp4': 'https://download.samplelib.com/mp4/sample-15s.mp4',
  'ForBiggerJoyrides.mp4': 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_2MB.mp4',
  'ForBiggerMeltdowns.mp4': 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
  'ElephantsDream.mp4': 'https://www.w3schools.com/html/mov_bbb.mp4',
  'SubaruOutbackOnStreetAndDirt.mp4': 'https://download.samplelib.com/mp4/sample-5s.mp4',
  'TearsOfSteel.mp4': 'https://download.samplelib.com/mp4/sample-10s.mp4',
};

const DEFAULT_VIDEO_URL = VIDEO_CDN_MAP['BigBuckBunny.mp4'];

function resolveVideoUrl(urlOrFilename) {
  if (!urlOrFilename) return DEFAULT_VIDEO_URL;
  const filename = urlOrFilename.split('/').pop().split('?')[0];
  return VIDEO_CDN_MAP[filename] || DEFAULT_VIDEO_URL;
}

module.exports = { VIDEO_CDN_MAP, DEFAULT_VIDEO_URL, resolveVideoUrl };
