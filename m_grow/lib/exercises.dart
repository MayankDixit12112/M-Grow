/// MET values are approximate (Compendium of Physical Activities).
/// kcal = MET x weight(kg) x hours.
class Exercise {
  final String name;
  final double met;
  final List<String> aliases;
  final double kmh; // typical speed, for "ran 5 km"; 0 if not distance-based
  final bool walk;

  const Exercise(this.name, this.met, this.aliases,
      {this.kmh = 0, this.walk = false});
}

const exercises = <Exercise>[
  Exercise('Walking', 3.5, ['walk', 'walked', 'walking', 'treadmill walk'],
      kmh: 5, walk: true),
  Exercise('Hiking', 6.0, ['hike', 'hiked', 'hiking', 'trek', 'trekking'],
      kmh: 4, walk: true),
  Exercise('Jogging', 7.0, ['jog', 'jogged', 'jogging'], kmh: 8),
  Exercise('Running', 9.0, ['run', 'ran', 'running'], kmh: 9),
  Exercise('Cycling', 6.0, ['cycle', 'cycled', 'cycling', 'bike', 'biking'],
      kmh: 15),
  Exercise('Swimming', 6.0, ['swim', 'swam', 'swimming']),
  Exercise('Yoga', 2.5, ['yoga', 'asana', 'surya namaskar']),
  Exercise('Stretching', 2.3, ['stretch', 'stretching']),
  Exercise('Pilates', 3.0, ['pilates']),
  Exercise('Gym / weights', 5.0,
      ['gym', 'weights', 'weight training', 'lifting', 'strength', 'workout']),
  Exercise('Bodyweight exercises', 3.8,
      ['pushups', 'push ups', 'pushup', 'squats', 'calisthenics', 'plank']),
  Exercise('HIIT', 8.0, ['hiit', 'interval training', 'crossfit']),
  Exercise('Skipping rope', 10.0, ['skipping', 'jump rope', 'rope']),
  Exercise('Dance / Zumba', 5.5, ['dance', 'danced', 'dancing', 'zumba']),
  Exercise('Aerobics', 6.5, ['aerobics']),
  Exercise('Football', 7.0, ['football', 'soccer']),
  Exercise('Cricket', 4.8, ['cricket']),
  Exercise('Badminton', 5.5, ['badminton']),
  Exercise('Tennis', 7.3, ['tennis']),
  Exercise('Basketball', 6.5, ['basketball']),
  Exercise('Volleyball', 4.0, ['volleyball']),
  Exercise('Table tennis', 4.0, ['table tennis', 'ping pong']),
  Exercise('Kabaddi / kho-kho', 7.0, ['kabaddi', 'kho kho', 'kho-kho']),
  Exercise('Martial arts', 8.0, ['karate', 'taekwondo', 'judo', 'martial arts']),
  Exercise('Boxing', 6.0, ['boxing']),
  Exercise('Rowing', 6.0, ['rowing']),
  Exercise('Elliptical', 5.0, ['elliptical', 'cross trainer']),
  Exercise('Climbing stairs', 5.0, ['stairs', 'climbing stairs']),
  Exercise('Active play', 4.5,
      ['play', 'playing', 'outdoor play', 'playground', 'tag']),
  Exercise('Housework', 3.3, ['housework', 'cleaning', 'sweeping', 'mopping']),
  Exercise('Gardening', 3.8, ['gardening', 'garden']),
];
