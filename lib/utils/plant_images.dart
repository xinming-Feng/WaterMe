import 'dart:math';

class PlantImages {
  static const List<String> plantImagePaths = [
    'assets/images/plants/pixel_plant_1.png',
    'assets/images/plants/pixel_plant_2.png',
    'assets/images/plants/pixel_plant_3.png',
    'assets/images/plants/pixel_plant_4.png',
    'assets/images/plants/pixel_plant_5.png',
    'assets/images/plants/pixel_plant_6.png',
    'assets/images/plants/pixel_plant_7.png',
    'assets/images/plants/pixel_plant_8.png',
    'assets/images/plants/pixel_plant_9.png',
    'assets/images/plants/pixel_plant_10.png',
    // 后续可以继续添加更多图片路径
  ];

  // 获取随机植物图片路径
  static String getRandomPlantImage() {
    final random = Random();
    return plantImagePaths[random.nextInt(plantImagePaths.length)];
  }

  // 根据索引获取植物图片路径
  static String getPlantImageByIndex(int index) {
    if (index < 0 || index >= plantImagePaths.length) {
      return plantImagePaths[0]; // 默认返回第一张图片
    }
    return plantImagePaths[index];
  }
  
  // 获取植物图片总数
  static int getPlantImagesCount() {
    return plantImagePaths.length;
  }
} 