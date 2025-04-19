import 'package:flutter/material.dart';
import '../widgets/pixel_title.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/plant_images.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:async';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _plantData = [];
  Map<String, StreamSubscription> _mqttSubscriptions = {};
  
  // MQTT client
  MqttServerClient? _client;
  final String _mqttServer = "4.tcp.eu.ngrok.io"; // Replace with your MQTT server address
  final int _mqttPort = 13087; // Replace with your MQTT server port
  final String _mqttUsername = "CEgroup1"; // If authentication is needed
  final String _mqttPassword = "group111111"; // If authentication is needed
  
  @override
  void initState() {
    super.initState();
    _loadPlantData();
    _connectMqtt();
  }
  
  @override
  void dispose() {
    // Cancel all MQTT subscriptions
    _mqttSubscriptions.forEach((key, subscription) {
      subscription.cancel();
    });
    
    // Disconnect MQTT
    _client?.disconnect();
    
    super.dispose();
  }
  
  // Connect to MQTT server
  Future<void> _connectMqtt() async {
    if (!FirebaseService.isUserLoggedIn) return;
    
    try {
      // Create MQTT client instance
      final client = MqttServerClient(_mqttServer, 'flutter_data_${DateTime.now().millisecondsSinceEpoch}');
      client.port = _mqttPort;
      client.keepAlivePeriod = 60;
      
      // Set authentication (if needed)
      final connMessage = MqttConnectMessage()
          .withClientIdentifier('flutter_data_${DateTime.now().millisecondsSinceEpoch}')
          .startClean();
      
      if (_mqttUsername.isNotEmpty) {
        connMessage.authenticateAs(_mqttUsername, _mqttPassword);
      }
      
      client.connectionMessage = connMessage;
      
      await client.connect();
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        _client = client;
        
        // Load device to MQTT topic associations
        await _subscribeToDeviceTopics();
      }
    } catch (e) {
      print('MQTT connection error: $e');
    }
  }
  
  // Subscribe to device topics
  Future<void> _subscribeToDeviceTopics() async {
    if (_client == null || !FirebaseService.isUserLoggedIn) return;
    
    try {
      final userId = FirebaseService.currentUser!.uid;
      
      // Get all user devices
      final devicesSnapshot = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .get();
      
      for (var doc in devicesSnapshot.docs) {
        final deviceId = doc.data()['deviceId'];
        if (deviceId != null) {
          final topic = 'waterme/devices/$deviceId';
          
          // Subscribe to device topic
          _client!.subscribe(topic, MqttQos.atLeastOnce);
          
          // Listen for device messages
          final subscription = _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
            for (var msg in c) {
              if (msg.topic.startsWith(topic)) {
                final MqttPublishMessage recMess = msg.payload as MqttPublishMessage;
                final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
                
                try {
                  final data = jsonDecode(payload);
                  _updatePlantData(deviceId, data);
                } catch (e) {
                  print('JSON parsing error: $e');
                }
              }
            }
          });
          
          _mqttSubscriptions[deviceId] = subscription;
        }
      }
    } catch (e) {
      print('Failed to subscribe to device topics: $e');
    }
  }
  
  // Update plant data
  void _updatePlantData(String deviceId, Map<String, dynamic> data) async {
    if (!FirebaseService.isUserLoggedIn) return;
    
    try {
      final userId = FirebaseService.currentUser!.uid;
      
      // Find plants associated with this device
      final plantsSnapshot = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('plants')
          .where('device_id', isEqualTo: deviceId)
          .get();
      
      for (var doc in plantsSnapshot.docs) {
        final plantId = doc.id;
        
        // Update plant data in Firebase
        await FirebaseService.firestore
            .collection('users')
            .doc(userId)
            .collection('plants')
            .doc(plantId)
            .update({
          'moisture': data['moisture_pct'] ?? 0,
          'temperature': data['temperature'] ?? 0,
          'last_updated': FieldValue.serverTimestamp(),
        });
        
        // Add to history collection
        await FirebaseService.firestore
            .collection('users')
            .doc(userId)
            .collection('plants')
            .doc(plantId)
            .collection('history')
            .add({
          'moisture': data['moisture_pct'] ?? 0,
          'temperature': data['temperature'] ?? 0,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Update local state
        setState(() {
          for (int i = 0; i < _plantData.length; i++) {
            if (_plantData[i]['id'] == plantId) {
              _plantData[i]['moisture'] = data['moisture_pct'] ?? _plantData[i]['moisture'];
              _plantData[i]['temperature'] = data['temperature'] ?? _plantData[i]['temperature'];
              
              // Add to time series data
              final List<Map<String, dynamic>> timeSeriesData = List<Map<String, dynamic>>.from(_plantData[i]['timeSeriesData']);
              
              // Limit to latest 50 data points
              if (timeSeriesData.length >= 50) {
                timeSeriesData.removeAt(0);
              }
              
              // Add new data point
              timeSeriesData.add({
                'time': timeSeriesData.isEmpty ? 0 : timeSeriesData.last['time'] + 1,
                'moisture': data['moisture_pct'] ?? 0,
                'temperature': data['temperature'] ?? 0,
              });
              
              _plantData[i]['timeSeriesData'] = timeSeriesData;
              break;
            }
          }
        });
      }
    } catch (e) {
      print('Failed to update plant data: $e');
    }
  }
  
  // Load plant data
  Future<void> _loadPlantData() async {
    if (!FirebaseService.isUserLoggedIn) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      final userId = FirebaseService.currentUser!.uid;
      
      // Get all user plants
      final plantsSnapshot = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('plants')
          .get();
      
      final List<Map<String, dynamic>> plantData = [];
      
      for (var doc in plantsSnapshot.docs) {
        final data = doc.data();
        final deviceId = data['device_id'];
        
        // Get history data
        List<Map<String, dynamic>> timeSeriesData = [];
        if (deviceId != null && deviceId.isNotEmpty) {
          final historySnapshot = await FirebaseService.firestore
              .collection('users')
              .doc(userId)
              .collection('plants')
              .doc(doc.id)
              .collection('history')
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();
          
          // Convert history data to time series format
          int timeIndex = 0;
          for (var historyDoc in historySnapshot.docs.reversed) {
            final historyData = historyDoc.data();
            timeSeriesData.add({
              'time': timeIndex,
              'moisture': historyData['moisture'] ?? 0,
              'temperature': historyData['temperature'] ?? 0,
            });
            timeIndex++;
          }
        }
        
        // If no history data, create sample data for chart display
        if (timeSeriesData.isEmpty) {
          final moisture = data['moisture'] ?? 50;
          final temperature = data['temperature'] ?? 22;
          
          for (int i = 0; i < 10; i++) {
            timeSeriesData.add({
              'time': i,
              'moisture': moisture,
              'temperature': temperature,
            });
          }
        }
        
        plantData.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Plant',
          'moisture': data['moisture'] ?? 0,
          'temperature': data['temperature'] ?? 0,
          'imagePath': data['image'] ?? PlantImages.getRandomPlantImage(),
          'timeSeriesData': timeSeriesData,
          'device_id': deviceId ?? '',
        });
      }
      
      setState(() {
        _plantData = plantData;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load plant data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4A8F3C),
                          ),
                        )
                      : _plantData.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.zero,
                                  border: Border.all(
                                    color: const Color(0xFF4A8F3C),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      size: 80,
                                      color: const Color(0xFF4A8F3C).withOpacity(0.7),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No plant data',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C5530),
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Add plants and connect sensors to view data',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF2C5530),
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _plantData.length,
                              itemBuilder: (context, index) {
                                final data = _plantData[index];
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
                                            if (data['device_id'] != null && data['device_id'].isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8.0),
                                                child: Icon(
                                                  Icons.sensors,
                                                  size: 16,
                                                  color: const Color(0xFF4A8F3C).withOpacity(0.7),
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
                                                maxX: (data['timeSeriesData'] as List).length > 0 
                                                    ? (data['timeSeriesData'] as List).length - 1.0 
                                                    : 4,
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
                                                      showTitles: false,
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
                                                  // Moisture curve
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
                                                  // Temperature curve
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
