import 'package:flutter/material.dart';
import '../widgets/pixel_title.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/plant_images.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  // 模拟数据 - 后期会替换为蓝牙实时数据
  final List<Map<String, dynamic>> plantData = [
    {
      'name': 'Pothos',
      'moisture': 75,
      'temperature': 22,
      'imagePath': PlantImages.getPlantImageByIndex(0),
      'timeSeriesData': [
        {'time': 0, 'moisture': 70, 'temperature': 22},
        {'time': 1, 'moisture': 72, 'temperature': 23},
        {'time': 2, 'moisture': 68, 'temperature': 24},
        {'time': 3, 'moisture': 75, 'temperature': 23},
        {'time': 4, 'moisture': 73, 'temperature': 22},
      ],
    },
    {
      'name': 'Succulent',
      'moisture': 30,
      'temperature': 25,
      'imagePath': PlantImages.getPlantImageByIndex(1),
      'timeSeriesData': [
        {'time': 0, 'moisture': 35, 'temperature': 24},
        {'time': 1, 'moisture': 32, 'temperature': 25},
        {'time': 2, 'moisture': 30, 'temperature': 26},
        {'time': 3, 'moisture': 28, 'temperature': 25},
        {'time': 4, 'moisture': 30, 'temperature': 24},
      ],
    },
    {
      'name': 'Cactus',
      'moisture': 20,
      'temperature': 28,
      'imagePath': PlantImages.getPlantImageByIndex(2),
      'timeSeriesData': [
        {'time': 0, 'moisture': 22, 'temperature': 27},
        {'time': 1, 'moisture': 20, 'temperature': 28},
        {'time': 2, 'moisture': 18, 'temperature': 29},
        {'time': 3, 'moisture': 20, 'temperature': 28},
        {'time': 4, 'moisture': 21, 'temperature': 27},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const PixelTitle(height: 80, centerTitle: false),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/pixel_background.png'),
            fit: BoxFit.cover,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: const Color(0xFF4A8F3C),
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'PLANT HEALTH OVERVIEW',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5530),
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: plantData.length,
                    itemBuilder: (context, index) {
                      final data = plantData[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.zero,
                          border: Border.all(
                            color: const Color(0xFF4A8F3C),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.zero,
                                      border: Border.all(
                                        color: const Color(0xFF4A8F3C),
                                        width: 2,
                                      ),
                                    ),
                                    child: Image.asset(
                                      data['imagePath'] ?? 'assets/images/plants/pixel_plant_1.png',
                                      width: 40,
                                      height: 40,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    data['name'].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C5530),
                                      fontFamily: 'monospace',
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildDataRow(
                                    icon: Icons.water_drop,
                                    label: 'MOISTURE',
                                    value: '${data['moisture']}%',
                                    color: const Color(0xFF4A8F3C),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildDataRow(
                                    icon: Icons.thermostat,
                                    label: 'TEMP',
                                    value: '${data['temperature']}°C',
                                    color: const Color(0xFFB87D44),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 24,
                                  top: 16,
                                  bottom: 16,
                                ),
                                child: SizedBox(
                                  height: 200,
                                  child: LineChart(
                                    LineChartData(
                                      minX: 0,
                                      maxX: 4,
                                      minY: 0,
                                      maxY: 100,
                                      clipData: FlClipData.all(),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: true,
                                        horizontalInterval: 15,
                                        verticalInterval: 1,
                                        getDrawingHorizontalLine: (value) {
                                          return FlLine(
                                            color: Colors.black12,
                                            strokeWidth: 1,
                                          );
                                        },
                                        getDrawingVerticalLine: (value) {
                                          return FlLine(
                                            color: Colors.black12,
                                            strokeWidth: 1,
                                          );
                                        },
                                      ),
                                      lineTouchData: LineTouchData(enabled: false),
                                      backgroundColor: Colors.white.withOpacity(0.9),
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            interval: 1,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                value.toInt().toString(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                  fontFamily: 'monospace',
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            interval: 20,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                value.toInt().toString(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                  fontFamily: 'monospace',
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border.all(
                                          color: Colors.black12,
                                          width: 1,
                                        ),
                                      ),
                                      lineBarsData: [
                                        // 湿度曲线
                                        LineChartBarData(
                                          spots: (data['timeSeriesData'] as List)
                                              .map((point) => FlSpot(
                                                  point['time'].toDouble(),
                                                  point['moisture'].toDouble()))
                                              .toList(),
                                          isCurved: true,
                                          color: const Color(0xFF4A8F3C),
                                          barWidth: 3,
                                          dotData: const FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: const Color(0xFF4A8F3C).withOpacity(0.1),
                                          ),
                                        ),
                                        // 温度曲线
                                        LineChartBarData(
                                          spots: (data['timeSeriesData'] as List)
                                              .map((point) => FlSpot(
                                                  point['time'].toDouble(),
                                                  point['temperature'].toDouble()))
                                              .toList(),
                                          isCurved: true,
                                          color: const Color(0xFFB87D44),
                                          barWidth: 3,
                                          dotData: const FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: const Color(0xFFB87D44).withOpacity(0.1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
