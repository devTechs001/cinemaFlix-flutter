const movies = [
  {
    id: 'dune2',
    title: 'Dune: Part Two',
    year: '2024',
    rating: '8.7',
    genre: 'Sci-Fi / Adventure',
    description: 'Paul Atreides unites with the Fremen to seek revenge against those who destroyed his family. As he faces a choice between the love of his life and the fate of the universe, he must prevent a terrible future only he can foresee.',
    cast: 'Timothée Chalamet, Zendaya, Rebecca Ferguson',
    director: 'Denis Villeneuve',
    duration: '2h 46m',
    videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4',
    posterUrl: 'https://picsum.photos/seed/dune2/300/450',
    gradientStart: '#1A1A2E',
    gradientEnd: '#16213E',
    tags: ['sci-fi', 'adventure', 'epic'],
  },
  {
    id: 'oppenheimer',
    title: 'Oppenheimer',
    year: '2023',
    rating: '8.4',
    genre: 'Drama / History',
    description: 'The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb during World War II. A gripping tale of ambition, morality, and consequence.',
    cast: 'Cillian Murphy, Emily Blunt, Matt Damon',
    director: 'Christopher Nolan',
    duration: '3h 0m',
    videoUrl: 'https://download.samplelib.com/mp4/sample-5s.mp4',
    posterUrl: 'https://picsum.photos/seed/oppenheimer/300/450',
    gradientStart: '#2D1B00',
    gradientEnd: '#1A1A1A',
    tags: ['drama', 'history', 'biography'],
  },
  {
    id: 'batman',
    title: 'The Batman',
    year: '2022',
    rating: '7.8',
    genre: 'Action / Crime',
    description: 'When a sadistic serial killer begins murdering key political figures in Gotham, Batman is forced to investigate the city\'s hidden corruption and question his family\'s involvement.',
    cast: 'Robert Pattinson, Zoë Kravitz, Jeffrey Wright',
    director: 'Matt Reeves',
    duration: '2h 56m',
    videoUrl: 'https://download.samplelib.com/mp4/sample-10s.mp4',
    posterUrl: 'https://picsum.photos/seed/batman/300/450',
    gradientStart: '#1A0000',
    gradientEnd: '#1E1E1E',
    tags: ['action', 'crime', 'superhero'],
  },
  {
    id: 'deadpool3',
    title: 'Deadpool 3',
    year: '2024',
    rating: '8.2',
    genre: 'Action / Comedy',
    description: 'The merc with a mouth returns alongside Wolverine in a time-traveling adventure that breaks the multiverse wide open. Expect chaos, cameos, and fourth-wall demolitions.',
    cast: 'Ryan Reynolds, Hugh Jackman, Emma Corrin',
    director: 'Shawn Levy',
    duration: '2h 10m',
    videoUrl: 'https://download.samplelib.com/mp4/sample-15s.mp4',
    posterUrl: 'https://picsum.photos/seed/deadpool3/300/450',
    gradientStart: '#2E0A0A',
    gradientEnd: '#1A1A1A',
    tags: ['action', 'comedy', 'superhero'],
  },
  {
    id: 'furiosa',
    title: 'Furiosa',
    year: '2024',
    rating: '8.0',
    genre: 'Action / Sci-Fi',
    description: 'Before her encounter with Max, a young Furiosa is taken from the Green Place of Many Mothers and falls into the hands of a great Biker Horde led by the Warlord Dementus.',
    cast: 'Anya Taylor-Joy, Chris Hemsworth, Tom Burke',
    director: 'George Miller',
    duration: '2h 28m',
    videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_2MB.mp4',
    posterUrl: 'https://picsum.photos/seed/furiosa/300/450',
    gradientStart: '#1A1A1A',
    gradientEnd: '#2D1B00',
    tags: ['action', 'sci-fi', 'adventure'],
  },
  {
    id: 'inception',
    title: 'Inception',
    year: '2010',
    rating: '8.8',
    genre: 'Sci-Fi / Thriller',
    description: 'A thief who steals corporate secrets through dream-sharing technology is given the task of planting an idea into the mind of a C.E.O. The ultimate heist: inception.',
    cast: 'Leonardo DiCaprio, Joseph Gordon-Levitt, Elliot Page',
    director: 'Christopher Nolan',
    duration: '2h 28m',
    videoUrl: 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
    posterUrl: 'https://picsum.photos/seed/inception/300/450',
    gradientStart: '#0D0D2B',
    gradientEnd: '#1A1A2E',
    tags: ['sci-fi', 'thriller', 'heist'],
  },
  {
    id: 'interstellar',
    title: 'Interstellar',
    year: '2014',
    rating: '8.7',
    genre: 'Sci-Fi / Drama',
    description: 'When Earth becomes uninhabitable, a former NASA pilot is tasked with leading a mission through a wormhole to find a new home for humanity among distant galaxies.',
    cast: 'Matthew McConaughey, Anne Hathaway, Jessica Chastain',
    director: 'Christopher Nolan',
    duration: '2h 49m',
    videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
    posterUrl: 'https://picsum.photos/seed/interstellar/300/450',
    gradientStart: '#0A0A1A',
    gradientEnd: '#1A2E1A',
    tags: ['sci-fi', 'drama', 'space'],
  },
  {
    id: 'joker',
    title: 'Joker',
    year: '2019',
    rating: '8.4',
    genre: 'Drama / Crime',
    description: 'A mentally troubled stand-up comedian embarks on a downward spiral that leads to the creation of an iconic villain. A gritty character study of society\'s outcasts.',
    cast: 'Joaquin Phoenix, Robert De Niro, Zazie Beetz',
    director: 'Todd Phillips',
    duration: '2h 2m',
    videoUrl: 'https://download.samplelib.com/mp4/sample-5s.mp4',
    posterUrl: 'https://picsum.photos/seed/joker/300/450',
    gradientStart: '#1A0A00',
    gradientEnd: '#2D1B00',
    tags: ['drama', 'crime', 'psychological'],
  },
  {
    id: 'tenet',
    title: 'Tenet',
    year: '2020',
    rating: '7.5',
    genre: 'Sci-Fi / Action',
    description: 'Armed with only one word, Tenet, and fighting for the survival of the entire world, a Protagonist journeys through a twilight world of international espionage on a mission that will unfold in something beyond real time.',
    cast: 'John David Washington, Robert Pattinson, Elizabeth Debicki',
    director: 'Christopher Nolan',
    duration: '2h 30m',
    videoUrl: 'https://download.samplelib.com/mp4/sample-10s.mp4',
    posterUrl: 'https://picsum.photos/seed/tenet/300/450',
    gradientStart: '#0A1A2E',
    gradientEnd: '#1A1A2E',
    tags: ['sci-fi', 'action', 'espionage'],
  },
  {
    id: 'matrix',
    title: 'The Matrix',
    year: '1999',
    rating: '8.7',
    genre: 'Sci-Fi / Action',
    description: 'When a beautiful stranger leads computer hacker Neo to a forbidding underworld, he discovers the shocking truth—the life he knows is the elaborate deception of an evil cyber-intelligence.',
    cast: 'Keanu Reeves, Laurence Fishburne, Carrie-Anne Moss',
    director: 'Lana Wachowski, Lilly Wachowski',
    duration: '2h 16m',
    videoUrl: 'https://download.samplelib.com/mp4/sample-5s.mp4',
    posterUrl: 'https://picsum.photos/seed/matrix/300/450',
    gradientStart: '#002800',
    gradientEnd: '#0D0D0D',
    tags: ['sci-fi', 'action', 'cyberpunk'],
  },
  {
    id: 'parasite',
    title: 'Parasite',
    year: '2019',
    rating: '8.5',
    genre: 'Drama / Thriller',
    description: 'Greed and class discrimination threaten the newly formed symbiotic relationship between the wealthy Park family and the destitute Kim clan in this darkly comic masterpiece.',
    cast: 'Song Kang-ho, Lee Sun-kyun, Cho Yeo-jeong',
    director: 'Bong Joon-ho',
    duration: '2h 12m',
    videoUrl: 'https://download.samplelib.com/mp4/sample-10s.mp4',
    posterUrl: 'https://picsum.photos/seed/parasite/300/450',
    gradientStart: '#1A1A1A',
    gradientEnd: '#2E1A00',
    tags: ['drama', 'thriller', 'comedy'],
  },
  {
    id: 'everything',
    title: 'Everything Everywhere All at Once',
    year: '2022',
    rating: '7.8',
    genre: 'Sci-Fi / Comedy',
    description: 'An aging Chinese immigrant is swept up in an insane adventure where she alone can save the world by exploring other universes connecting with the lives she could have led.',
    cast: 'Michelle Yeoh, Ke Huy Quan, Jamie Lee Curtis',
    director: 'Daniel Kwan, Daniel Scheinert',
    duration: '2h 19m',
    videoUrl: 'https://download.samplelib.com/mp4/sample-15s.mp4',
    posterUrl: 'https://picsum.photos/seed/everything/300/450',
    gradientStart: '#2E002E',
    gradientEnd: '#1A1A2E',
    tags: ['sci-fi', 'comedy', 'action'],
  },
  {
    id: 'spiderverse',
    title: 'Spider-Man: Across the Spider-Verse',
    year: '2023',
    rating: '8.6',
    genre: 'Animation / Action',
    description: 'Miles Morales catapults across the Multiverse, where he encounters a team of Spider-People charged with protecting its existence. When the heroes clash on how to handle a new threat, Miles must redefine what it means to be a hero.',
    cast: 'Shameik Moore, Hailee Steinfeld, Oscar Isaac',
    director: 'Joaquim Dos Santos, Kemp Powers, Justin K. Thompson',
    duration: '2h 20m',
    videoUrl: 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
    posterUrl: 'https://picsum.photos/seed/spiderverse/300/450',
    gradientStart: '#1A002E',
    gradientEnd: '#001A2E',
    tags: ['animation', 'action', 'superhero'],
  },
  {
    id: 'shawshank',
    title: 'The Shawshank Redemption',
    year: '1994',
    rating: '9.3',
    genre: 'Drama',
    description: 'Over the course of several years, two convicts form a friendship, seeking consolation and eventual redemption through basic compassion in this powerful adaptation of Stephen King\'s novella.',
    cast: 'Tim Robbins, Morgan Freeman, Bob Gunton',
    director: 'Frank Darabont',
    duration: '2h 22m',
    videoUrl: 'https://download.samplelib.com/mp4/sample-5s.mp4',
    posterUrl: 'https://picsum.photos/seed/shawshank/300/450',
    gradientStart: '#0D1A2E',
    gradientEnd: '#1A0D00',
    tags: ['drama', 'prison', 'redemption'],
  },
  {
    id: 'pulp-fiction',
    title: 'Pulp Fiction',
    year: '1994',
    rating: '8.9',
    genre: 'Crime / Drama',
    description: 'The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption in this iconic Tarantino masterpiece.',
    cast: 'John Travolta, Uma Thurman, Samuel L. Jackson',
    director: 'Quentin Tarantino',
    duration: '2h 34m',
    videoUrl: 'https://download.samplelib.com/mp4/sample-10s.mp4',
    posterUrl: 'https://picsum.photos/seed/pulp-fiction/300/450',
    gradientStart: '#1A0A0A',
    gradientEnd: '#1A1A00',
    tags: ['crime', 'drama', 'classic'],
  },
  {
    id: 'dark-knight',
    title: 'The Dark Knight',
    year: '2008',
    rating: '9.0',
    genre: 'Action / Crime',
    description: 'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.',
    cast: 'Christian Bale, Heath Ledger, Aaron Eckhart',
    director: 'Christopher Nolan',
    duration: '2h 32m',
    videoUrl: 'https://download.samplelib.com/mp4/sample-10s.mp4',
    posterUrl: 'https://picsum.photos/seed/dark-knight/300/450',
    gradientStart: '#0D0D0D',
    gradientEnd: '#1A0000',
    tags: ['action', 'crime', 'superhero'],
  },
  {
    id: 'goodfellas',
    title: 'Goodfellas',
    year: '1990',
    rating: '8.7',
    genre: 'Crime / Biography',
    description: 'The story of Henry Hill and his life in the mob, covering his relationship with his wife Karen Hill and his mob partners Jimmy Conway and Tommy DeVito in the Italian-American crime syndicate.',
    cast: 'Robert De Niro, Ray Liotta, Joe Pesci',
    director: 'Martin Scorsese',
    duration: '2h 26m',
    videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4',
    posterUrl: 'https://picsum.photos/seed/goodfellas/300/450',
    gradientStart: '#1A0D00',
    gradientEnd: '#0D0D0D',
    tags: ['crime', 'biography', 'classic'],
  },
];

const genres = [...new Set(movies.flatMap(m => m.genre.split(' / ')))].sort();
const allTags = [...new Set(movies.flatMap(m => m.tags))].sort();

function getMovies({ page = 1, limit = 20, genre, search, tag } = {}) {
  let filtered = [...movies];

  if (genre) {
    filtered = filtered.filter(m => m.genre.toLowerCase().includes(genre.toLowerCase()));
  }

  if (tag) {
    filtered = filtered.filter(m => m.tags.includes(tag.toLowerCase()));
  }

  if (search) {
    const q = search.toLowerCase();
    filtered = filtered.filter(m =>
      m.title.toLowerCase().includes(q) ||
      m.genre.toLowerCase().includes(q) ||
      m.director.toLowerCase().includes(q) ||
      m.cast.toLowerCase().includes(q) ||
      m.description.toLowerCase().includes(q)
    );
  }

  const total = filtered.length;
  const start = (page - 1) * limit;
  const items = filtered.slice(start, start + limit);

  return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
}

function getMovieById(id) {
  return movies.find(m => m.id === id) || null;
}

function getGenres() {
  return genres;
}

function getTags() {
  return allTags;
}

module.exports = { movies, getMovies, getMovieById, getGenres, getTags };
