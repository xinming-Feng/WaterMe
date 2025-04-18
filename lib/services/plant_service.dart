import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant.dart';

class PlantService {
  static const String _storageKey = 'plants';

  // Get all plants
  Future<List<Plant>> getPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final plantsJson = prefs.getStringList(_storageKey) ?? [];

    return plantsJson
        .map((plantJson) => Plant.fromJson(jsonDecode(plantJson)))
        .toList();
  }

  // Add new plant
  Future<void> addPlant(Plant plant) async {
    final prefs = await SharedPreferences.getInstance();
    final plantsJson = prefs.getStringList(_storageKey) ?? [];

    plantsJson.add(jsonEncode(plant.toJson()));
    await prefs.setStringList(_storageKey, plantsJson);
  }

  // Update plant information
  Future<void> updatePlant(Plant plant) async {
    final prefs = await SharedPreferences.getInstance();
    final plantsJson = prefs.getStringList(_storageKey) ?? [];

    final plantsList =
        plantsJson
            .map((plantJson) => Plant.fromJson(jsonDecode(plantJson)))
            .toList();

    final index = plantsList.indexWhere((p) => p.id == plant.id);
    if (index != -1) {
      plantsList[index] = plant;

      final updatedPlantsJson =
          plantsList.map((p) => jsonEncode(p.toJson())).toList();

      await prefs.setStringList(_storageKey, updatedPlantsJson);
    }
  }

  // Delete plant
  Future<void> deletePlant(String plantId) async {
    final prefs = await SharedPreferences.getInstance();
    final plantsJson = prefs.getStringList(_storageKey) ?? [];

    final plantsList =
        plantsJson
            .map((plantJson) => Plant.fromJson(jsonDecode(plantJson)))
            .toList();

    plantsList.removeWhere((plant) => plant.id == plantId);

    final updatedPlantsJson =
        plantsList.map((p) => jsonEncode(p.toJson())).toList();

    await prefs.setStringList(_storageKey, updatedPlantsJson);
  }

  // Record watering
  Future<void> recordWatering(String plantId) async {
    final plants = await getPlants();
    final plantIndex = plants.indexWhere((p) => p.id == plantId);

    if (plantIndex != -1) {
      final plant = plants[plantIndex];
      final now = DateTime.now();

      // Calculate next watering time (example: 7 days later)
      final nextWatering = now.add(const Duration(days: 7));

      final updatedPlant = plant.copyWith(
        lastWatered: now,
        nextWatering: nextWatering,
      );

      await updatePlant(updatedPlant);
    }
  }

  // Get plants that need watering
  Future<List<Plant>> getPlantsNeedingWater() async {
    final plants = await getPlants();
    final now = DateTime.now();

    return plants.where((plant) => plant.nextWatering.isBefore(now)).toList();
  }
}
