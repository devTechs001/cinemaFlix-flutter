import 'package:flutter/material.dart';

class SampleMovie {
  final String id;
  final String title;
  final String year;
  final String rating;
  final String genre;
  final String description;
  final String cast;
  final String director;
  final String duration;
  final String? videoUrl;
  final Color gradientStart;
  final Color gradientEnd;

  const SampleMovie({
    required this.id,
    required this.title,
    required this.year,
    required this.rating,
    required this.genre,
    required this.description,
    required this.cast,
    required this.director,
    required this.duration,
    this.videoUrl,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

const sampleMovies = [
  SampleMovie(
    id: 'dune2',
    title: 'Dune: Part Two',
    year: '2024',
    rating: '8.7',
    genre: 'Sci-Fi / Adventure',
    description:
        'Paul Atreides unites with the Fremen to seek revenge against those who destroyed his family. As he faces a choice between the love of his life and the fate of the universe, he must prevent a terrible future only he can foresee.',
    cast: 'Timothée Chalamet, Zendaya, Rebecca Ferguson',
    director: 'Denis Villeneuve',
    duration: '2h 46m',
    videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
    gradientStart: Color(0xFF1A1A2E),
    gradientEnd: Color(0xFF16213E),
  ),
  SampleMovie(
    id: 'oppenheimer',
    title: 'Oppenheimer',
    year: '2023',
    rating: '8.4',
    genre: 'Drama / History',
    description:
        'The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb during World War II. A gripping tale of ambition, morality, and consequence.',
    cast: 'Cillian Murphy, Emily Blunt, Matt Damon',
    director: 'Christopher Nolan',
    duration: '3h 0m',
    videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
    gradientStart: Color(0xFF2D1B00),
    gradientEnd: Color(0xFF1A1A1A),
  ),
  SampleMovie(
    id: 'batman',
    title: 'The Batman',
    year: '2022',
    rating: '7.8',
    genre: 'Action / Crime',
    description:
        'When a sadistic serial killer begins murdering key political figures in Gotham, Batman is forced to investigate the city\'s hidden corruption and question his family\'s involvement.',
    cast: 'Robert Pattinson, Zoë Kravitz, Jeffrey Wright',
    director: 'Matt Reeves',
    duration: '2h 56m',
    videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
    gradientStart: Color(0xFF1A0000),
    gradientEnd: Color(0xFF1E1E1E),
  ),
  SampleMovie(
    id: 'deadpool3',
    title: 'Deadpool 3',
    year: '2024',
    rating: '8.2',
    genre: 'Action / Comedy',
    description:
        'The merc with a mouth returns alongside Wolverine in a time-traveling adventure that breaks the multiverse wide open. Expect chaos, cameos, and fourth-wall demolitions.',
    cast: 'Ryan Reynolds, Hugh Jackman, Emma Corrin',
    director: 'Shawn Levy',
    duration: '2h 10m',
    gradientStart: Color(0xFF2E0A0A),
    gradientEnd: Color(0xFF1A1A1A),
  ),
  SampleMovie(
    id: 'furiosa',
    title: 'Furiosa',
    year: '2024',
    rating: '8.0',
    genre: 'Action / Sci-Fi',
    description:
        'Before her encounter with Max, a young Furiosa is taken from the Green Place of Many Mothers and falls into the hands of a great Biker Horde led by the Warlord Dementus.',
    cast: 'Anya Taylor-Joy, Chris Hemsworth, Tom Burke',
    director: 'George Miller',
    duration: '2h 28m',
    gradientStart: Color(0xFF1A1A1A),
    gradientEnd: Color(0xFF2D1B00),
  ),
  SampleMovie(
    id: 'inception',
    title: 'Inception',
    year: '2010',
    rating: '8.8',
    genre: 'Sci-Fi / Thriller',
    description:
        'A thief who steals corporate secrets through dream-sharing technology is given the task of planting an idea into the mind of a C.E.O. The ultimate heist: inception.',
    cast: 'Leonardo DiCaprio, Joseph Gordon-Levitt, Elliot Page',
    director: 'Christopher Nolan',
    duration: '2h 28m',
    gradientStart: Color(0xFF0D0D2B),
    gradientEnd: Color(0xFF1A1A2E),
  ),
  SampleMovie(
    id: 'interstellar',
    title: 'Interstellar',
    year: '2014',
    rating: '8.7',
    genre: 'Sci-Fi / Drama',
    description:
        'When Earth becomes uninhabitable, a former NASA pilot is tasked with leading a mission through a wormhole to find a new home for humanity among distant galaxies.',
    cast: 'Matthew McConaughey, Anne Hathaway, Jessica Chastain',
    director: 'Christopher Nolan',
    duration: '2h 49m',
    gradientStart: Color(0xFF0A0A1A),
    gradientEnd: Color(0xFF1A2E1A),
  ),
  SampleMovie(
    id: 'joker',
    title: 'Joker',
    year: '2019',
    rating: '8.4',
    genre: 'Drama / Crime',
    description:
        'A mentally troubled stand-up comedian embarks on a downward spiral that leads to the creation of an iconic villain. A gritty character study of society\'s outcasts.',
    cast: 'Joaquin Phoenix, Robert De Niro, Zazie Beetz',
    director: 'Todd Phillips',
    duration: '2h 2m',
    gradientStart: Color(0xFF1A0A00),
    gradientEnd: Color(0xFF2D1B00),
  ),
];

SampleMovie getSampleMovieById(String id) {
  return sampleMovies.firstWhere((m) => m.id == id);
}

List<SampleMovie> getMoviesByGenre(String genre) {
  return sampleMovies.where((m) => m.genre.contains(genre)).toList();
}
