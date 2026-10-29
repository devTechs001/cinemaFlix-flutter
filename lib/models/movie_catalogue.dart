import 'package:flutter/material.dart';
import 'movie.dart';

export 'movie.dart';

/// Bundled movie catalogue: real titles and metadata with poster images
/// served from the TMDB image CDN (image.tmdb.org).
///
/// This is the offline/default source. At runtime [MovieService] replaces
/// it with rows from the Supabase `movies` table when that table has data
/// (see supabase/schema.sql for the table + seed), and keeps it updated via
/// Realtime. If a poster URL ever fails, the UI falls back to the
/// per-movie gradient artwork (MoviePoster widget).
///
/// videoUrl values point at openly-licensed sample streams (Google GTV
/// sample bucket / Blender open movies) so playback works end-to-end;
/// swap in licensed trailer/feature URLs per title when available.
const _img = 'https://image.tmdb.org/t/p/w500';
const _vid = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample';

const movieCatalogue = <Movie>[
  Movie(
    id: 'dune2',
    title: 'Dune: Part Two',
    year: '2024', rating: '8.5', genre: 'Sci-Fi / Adventure',
    description: 'Paul Atreides unites with the Fremen to seek revenge against those who destroyed his family. As he faces a choice between the love of his life and the fate of the universe, he must prevent a terrible future only he can foresee.',
    cast: 'Timothee Chalamet, Zendaya, Rebecca Ferguson',
    director: 'Denis Villeneuve', duration: '2h 46m',
    posterUrl: '$_img/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
    videoUrl: '$_vid/BigBuckBunny.mp4',
    gradientStart: Color(0xFF1A1A2E), gradientEnd: Color(0xFF16213E),
  ),
  Movie(
    id: 'oppenheimer',
    title: 'Oppenheimer',
    year: '2023', rating: '8.3', genre: 'Drama / History',
    description: 'The story of J. Robert Oppenheimer and his pivotal role in the development of the atomic bomb during World War II. A gripping tale of ambition, morality and consequence.',
    cast: 'Cillian Murphy, Emily Blunt, Matt Damon',
    director: 'Christopher Nolan', duration: '3h 0m',
    posterUrl: '$_img/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
    videoUrl: '$_vid/ElephantsDream.mp4',
    gradientStart: Color(0xFF2D1B00), gradientEnd: Color(0xFF1A1A1A),
  ),
  Movie(
    id: 'batman',
    title: 'The Batman',
    year: '2022', rating: '7.8', genre: 'Action / Crime',
    description: 'When a sadistic serial killer targets key political figures in Gotham, Batman must investigate the city and its hidden corruption and question his own family legacy.',
    cast: 'Robert Pattinson, Zoe Kravitz, Jeffrey Wright',
    director: 'Matt Reeves', duration: '2h 56m',
    posterUrl: '$_img/74xTEgt7R36Fpooo50r9T25onhq.jpg',
    videoUrl: '$_vid/Sintel.mp4',
    gradientStart: Color(0xFF1A0000), gradientEnd: Color(0xFF1E1E1E),
  ),
  Movie(
    id: 'deadpool3',
    title: 'Deadpool & Wolverine',
    year: '2024', rating: '7.7', genre: 'Action / Comedy',
    description: 'The merc with a mouth returns alongside Wolverine in a time-twisting adventure that rips the multiverse wide open. Expect chaos, cameos and fourth-wall demolitions.',
    cast: 'Ryan Reynolds, Hugh Jackman, Emma Corrin',
    director: 'Shawn Levy', duration: '2h 8m',
    posterUrl: '$_img/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
    videoUrl: '$_vid/ForBiggerBlazes.mp4',
    gradientStart: Color(0xFF2E0A0A), gradientEnd: Color(0xFF1A1A1A),
  ),
  Movie(
    id: 'furiosa',
    title: 'Furiosa: A Mad Max Saga',
    year: '2024', rating: '7.6', genre: 'Action / Sci-Fi',
    description: 'Snatched from the Green Place of Many Mothers, young Furiosa falls into the hands of warlord Dementus and his biker horde as she plots her path home across the Wasteland.',
    cast: 'Anya Taylor-Joy, Chris Hemsworth, Tom Burke',
    director: 'George Miller', duration: '2h 28m',
    posterUrl: '$_img/iADOJ8Zymht2JPMoy3R7xceZprc.jpg',
    videoUrl: '$_vid/ForBiggerEscapes.mp4',
    gradientStart: Color(0xFF1A1A1A), gradientEnd: Color(0xFF2D1B00),
  ),
  Movie(
    id: 'inception',
    title: 'Inception',
    year: '2010', rating: '8.8', genre: 'Sci-Fi / Thriller',
    description: 'A thief who steals corporate secrets through dream-sharing technology is given the inverse task of planting an idea into the mind of a CEO. The ultimate heist: inception.',
    cast: 'Leonardo DiCaprio, Joseph Gordon-Levitt, Elliot Page',
    director: 'Christopher Nolan', duration: '2h 28m',
    posterUrl: '$_img/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
    videoUrl: '$_vid/TearsOfSteel.mp4',
    gradientStart: Color(0xFF0D0D2B), gradientEnd: Color(0xFF1A1A2E),
  ),
  Movie(
    id: 'interstellar',
    title: 'Interstellar',
    year: '2014', rating: '8.7', genre: 'Sci-Fi / Drama',
    description: 'When Earth becomes uninhabitable, a former NASA pilot leads a mission through a wormhole in search of a new home for humanity among distant galaxies.',
    cast: 'Matthew McConaughey, Anne Hathaway, Jessica Chastain',
    director: 'Christopher Nolan', duration: '2h 49m',
    posterUrl: '$_img/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
    videoUrl: '$_vid/Sintel.mp4',
    gradientStart: Color(0xFF0A0A1A), gradientEnd: Color(0xFF1A2E1A),
  ),
  Movie(
    id: 'joker',
    title: 'Joker',
    year: '2019', rating: '8.4', genre: 'Drama / Crime',
    description: 'A mentally troubled stand-up comedian embarks on a downward spiral that leads to the creation of an iconic villain. A gritty character study of a society that looks away.',
    cast: 'Joaquin Phoenix, Robert De Niro, Zazie Beetz',
    director: 'Todd Phillips', duration: '2h 2m',
    posterUrl: '$_img/udDclJoHjfjb8Ekgsd4FDteOkCU.jpg',
    videoUrl: '$_vid/ForBiggerMeltdowns.mp4',
    gradientStart: Color(0xFF1A0A00), gradientEnd: Color(0xFF2D1B00),
  ),
  Movie(
    id: 'dark-knight',
    title: 'The Dark Knight',
    year: '2008', rating: '9.0', genre: 'Action / Crime',
    description: 'Batman raises the stakes in his war on crime, but the Joker, a criminal mastermind with a twisted smile, plunges Gotham into anarchy and forces him ever closer to crossing the line.',
    cast: 'Christian Bale, Heath Ledger, Aaron Eckhart',
    director: 'Christopher Nolan', duration: '2h 32m',
    posterUrl: '$_img/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
    videoUrl: '$_vid/BigBuckBunny.mp4',
    gradientStart: Color(0xFF0B1026), gradientEnd: Color(0xFF1C2B4A),
  ),
  Movie(
    id: 'pulp-fiction',
    title: 'Pulp Fiction',
    year: '1994', rating: '8.9', genre: 'Crime / Thriller',
    description: 'The lives of two mob hitmen, a boxer, a gangster and his wife intertwine in four tales of violence and redemption told out of order.',
    cast: 'John Travolta, Samuel L. Jackson, Uma Thurman',
    director: 'Quentin Tarantino', duration: '2h 34m',
    posterUrl: '$_img/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg',
    videoUrl: '$_vid/ForBiggerFun.mp4',
    gradientStart: Color(0xFF260B0B), gradientEnd: Color(0xFF3A1C00),
  ),
  Movie(
    id: 'fight-club',
    title: 'Fight Club',
    year: '1999', rating: '8.8', genre: 'Drama',
    description: 'An insomniac office worker and a devil-may-care soap maker form an underground fight club that evolves into something far more dangerous.',
    cast: 'Brad Pitt, Edward Norton, Helena Bonham Carter',
    director: 'David Fincher', duration: '2h 19m',
    posterUrl: '$_img/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
    videoUrl: '$_vid/ElephantsDream.mp4',
    gradientStart: Color(0xFF10151F), gradientEnd: Color(0xFF2E1A2E),
  ),
  Movie(
    id: 'matrix',
    title: 'The Matrix',
    year: '1999', rating: '8.7', genre: 'Sci-Fi / Action',
    description: 'A hacker discovers the shocking truth about his reality and his role in the war against its controllers, and must choose between comfortable illusion and brutal freedom.',
    cast: 'Keanu Reeves, Laurence Fishburne, Carrie-Anne Moss',
    director: 'The Wachowskis', duration: '2h 16m',
    posterUrl: '$_img/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg',
    videoUrl: '$_vid/TearsOfSteel.mp4',
    gradientStart: Color(0xFF001A05), gradientEnd: Color(0xFF0B2B12),
  ),
  Movie(
    id: 'forrest-gump',
    title: 'Forrest Gump',
    year: '1994', rating: '8.8', genre: 'Drama / Romance',
    description: 'A kind-hearted man from Alabama unwittingly influences several defining historical events in 20th-century America while searching for his childhood love.',
    cast: 'Tom Hanks, Robin Wright, Gary Sinise',
    director: 'Robert Zemeckis', duration: '2h 22m',
    posterUrl: '$_img/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg',
    videoUrl: '$_vid/ForBiggerJoyrides.mp4',
    gradientStart: Color(0xFF0F1E2B), gradientEnd: Color(0xFF27354A),
  ),
  Movie(
    id: 'titanic',
    title: 'Titanic',
    year: '1997', rating: '7.9', genre: 'Romance / Drama',
    description: 'A seventeen-year-old aristocrat falls in love with a kind but poor artist aboard the luxurious, ill-fated R.M.S. Titanic.',
    cast: 'Leonardo DiCaprio, Kate Winslet, Billy Zane',
    director: 'Cameron', duration: '3h 14m',
    posterUrl: '$_img/9xjZS2rlVxm8SFx8kPC3aIGCOYQ.jpg',
    videoUrl: '$_vid/Sintel.mp4',
    gradientStart: Color(0xFF07182B), gradientEnd: Color(0xFF14425E),
  ),
  Movie(
    id: 'endgame',
    title: 'Avengers: Endgame',
    year: '2019', rating: '8.4', genre: 'Action / Adventure',
    description: 'After the devastating events that wiped out half of all life, the remaining Avengers assemble once more to undo the snap and restore the universe.',
    cast: 'Robert Downey Jr., Chris Evans, Mark Ruffalo',
    director: 'Anthony and Joe Russo', duration: '3h 1m',
    posterUrl: '$_img/or06FN3Dka5tukK1e9sl16pB3iy.jpg',
    videoUrl: '$_vid/BigBuckBunny.mp4',
    gradientStart: Color(0xFF160B2E), gradientEnd: Color(0xFF2E1065),
  ),
  Movie(
    id: 'no-way-home',
    title: 'Spider-Man: No Way Home',
    year: '2021', rating: '8.2', genre: 'Action / Adventure',
    description: 'When a spell goes wrong, Peter Parker must face villains from every universe that knows Spider-Man and discover what it truly means to wear the mask.',
    cast: 'Tom Holland, Zendaya, Benedict Cumberbatch',
    director: 'Jon Watts', duration: '2h 28m',
    posterUrl: '$_img/1g0dhYtq4irTY1GPXvft6k4YLjm.jpg',
    videoUrl: '$_vid/ForBiggerBlazes.mp4',
    gradientStart: Color(0xFF2B0A12), gradientEnd: Color(0xFF121E3A),
  ),
  Movie(
    id: 'avatar-2',
    title: 'Avatar: The Way of Water',
    year: '2022', rating: '7.6', genre: 'Sci-Fi / Adventure',
    description: 'Jake Sully and Neytiri have formed a family on Pandora. When an ancient threat resurfaces, they must fight a difficult war against the humans and protect what matters most.',
    cast: 'Sam Worthington, Zoe Saldana, Sigourney Weaver',
    director: 'Cameron', duration: '3h 12m',
    posterUrl: '$_img/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
    videoUrl: '$_vid/ElephantsDream.mp4',
    gradientStart: Color(0xFF03212E), gradientEnd: Color(0xFF075E75),
  ),
  Movie(
    id: 'john-wick-4',
    title: 'John Wick: Chapter 4',
    year: '2023', rating: '7.7', genre: 'Action / Thriller',
    description: 'With the price on his head ever increasing, John Wick uncovers a path to defeating the High Table. But before he can earn his freedom, he must face a new enemy across the globe.',
    cast: 'Keanu Reeves, Donnie Yen, Bill Skarsgard',
    director: 'Chad Stahelski', duration: '2h 49m',
    posterUrl: '$_img/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg',
    videoUrl: '$_vid/ForBiggerEscapes.mp4',
    gradientStart: Color(0xFF12071F), gradientEnd: Color(0xFF31113D),
  ),
  Movie(
    id: 'top-gun-maverick',
    title: 'Top Gun: Maverick',
    year: '2022', rating: '8.3', genre: 'Action / Drama',
    description: 'After more than thirty years of service, Pete Mitchell must confront the ghosts of his past when he trains a new squad of graduates for an impossible mission.',
    cast: 'Tom Cruise, Miles Teller, Jennifer Connelly',
    director: 'Joseph Kosinski', duration: '2h 10m',
    posterUrl: '$_img/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
    videoUrl: '$_vid/SubaruOutbackOnStreetAndDirt.mp4',
    gradientStart: Color(0xFF2B1607), gradientEnd: Color(0xFF17324A),
  ),
  Movie(
    id: 'everything-everywhere',
    title: 'Everything Everywhere All at Once',
    year: '2022', rating: '7.8', genre: 'Sci-Fi / Comedy',
    description: 'An ageing Chinese immigrant is swept up in an insane adventure where she alone can save existence by exploring other universes and the lives she could have led.',
    cast: 'Michelle Yeoh, Ke Huy Quan, Stephanie Hsu',
    director: 'Daniel Kwan, Daniel Scheinert', duration: '2h 19m',
    posterUrl: '$_img/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg',
    videoUrl: '$_vid/ForBiggerFun.mp4',
    gradientStart: Color(0xFF1E0A2B), gradientEnd: Color(0xFF3A1454),
  ),
];

Movie? getMovieById(String id) {
  for (final m in movieCatalogue) {
    if (m.id == id) return m;
  }
  return null;
}

List<Movie> getMoviesByGenre(String genre) {
  return movieCatalogue.where((m) => m.genre.contains(genre)).toList();
}

List<Movie> getTrendingMovies({int limit = 10}) {
  final sorted = [...movieCatalogue]
    ..sort((a, b) => (double.tryParse(b.rating) ?? 0)
        .compareTo(double.tryParse(a.rating) ?? 0));
  return sorted.take(limit).toList();
}
