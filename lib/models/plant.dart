class Plant {
  final String id;
  final String name;
  final String species;
  final String? imagePath;
  final DateTime lastWatered;
  final DateTime nextWatering;
  final String health;
  final int moistureLevel; // 湿度百分比 (moisture percentage)
  final int lightLevel; // 光照百分比 (light percentage)
  final double temperature; // 温度（摄氏度） (temperature in Celsius)

  Plant({
    required this.id,
    required this.name,
    required this.species,
    this.imagePath,
    required this.lastWatered,
    required this.nextWatering,
    required this.health,
    required this.moistureLevel,
    required this.lightLevel,
    required this.temperature,
  });

  // Create Plant object from JSON
  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'],
      name: json['name'],
      species: json['species'],
      imagePath: json['imagePath'],
      lastWatered: DateTime.parse(json['lastWatered']),
      nextWatering: DateTime.parse(json['nextWatering']),
      health: json['health'],
      moistureLevel: json['moistureLevel'],
      lightLevel: json['lightLevel'],
      temperature: json['temperature'].toDouble(),
    );
  }

  // Convert Plant object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'imagePath': imagePath,
      'lastWatered': lastWatered.toIso8601String(),
      'nextWatering': nextWatering.toIso8601String(),
      'health': health,
      'moistureLevel': moistureLevel,
      'lightLevel': lightLevel,
      'temperature': temperature,
    };
  }

  // Create a copy of Plant object and update some properties
  Plant copyWith({
    String? id,
    String? name,
    String? species,
    String? imagePath,
    DateTime? lastWatered,
    DateTime? nextWatering,
    String? health,
    int? moistureLevel,
    int? lightLevel,
    double? temperature,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      imagePath: imagePath ?? this.imagePath,
      lastWatered: lastWatered ?? this.lastWatered,
      nextWatering: nextWatering ?? this.nextWatering,
      health: health ?? this.health,
      moistureLevel: moistureLevel ?? this.moistureLevel,
      lightLevel: lightLevel ?? this.lightLevel,
      temperature: temperature ?? this.temperature,
    );
  }
}
