class AppNotification {
  final String id;
  final String title;
  final String body;
  final String time;
  final String? imageUrl;
  final NotificationType type;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.imageUrl,
    required this.type,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      time: time,
      imageUrl: imageUrl,
      type: type,
      read: read ?? this.read,
    );
  }
}

enum NotificationType {
  movie,
  chat,
  review,
  system,
  live,
}

const sampleNotifications = [
  AppNotification(
    id: '1',
    title: 'New Release',
    body: 'Deadpool & Wolverine is now streaming! Watch it now.',
    time: '2m ago',
    type: NotificationType.movie,
  ),
  AppNotification(
    id: '2',
    title: 'Live Now',
    body: 'Movie Chat Room: Discussing Inception with 24 people',
    time: '5m ago',
    type: NotificationType.live,
  ),
  AppNotification(
    id: '3',
    title: 'Sarah replied',
    body: 'Sarah commented on your review of Dune: Part Two',
    time: '1h ago',
    type: NotificationType.chat,
  ),
  AppNotification(
    id: '4',
    title: 'Trending Alert',
    body: '"Oppenheimer" is trending #1 in your region today.',
    time: '3h ago',
    type: NotificationType.movie,
  ),
  AppNotification(
    id: '5',
    title: 'New Review',
    body: 'Mike Chen rated The Batman 4 stars: "Amazing cinematography"',
    time: '5h ago',
    type: NotificationType.review,
  ),
  AppNotification(
    id: '6',
    title: 'Welcome!',
    body: 'Welcome to CinemaFlix! Complete your profile to get started.',
    time: '1d ago',
    type: NotificationType.system,
  ),
  AppNotification(
    id: '7',
    title: 'Movie Night',
    body: 'Your friends are planning a movie night. Join them!',
    time: '2d ago',
    type: NotificationType.live,
  ),
  AppNotification(
    id: '8',
    title: 'Watchlist Update',
    body: '3 movies in your watchlist are now available.',
    time: '3d ago',
    type: NotificationType.system,
  ),
];
