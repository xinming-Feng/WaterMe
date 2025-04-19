import 'package:flutter/material.dart';
import '../widgets/pixel_title.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import '../services/firebase_service.dart';
import '../utils/plant_images.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _deviceIdController = TextEditingController();
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isSearching = false;
  bool _deviceFound = false;
  Map<String, dynamic>? _deviceData;
  
  // MQTT client
  MqttServerClient? _client;
  final String _mqttServer = "4.tcp.eu.ngrok.io"; // Replace with your MQTT server address
  final int _mqttPort = 13087; // Replace with your MQTT server port
  final String _mqttUsername = "CEgroup1"; // If authentication is needed
  final String _mqttPassword = "group111111"; // If authentication is needed
  
  // Plant registration form controllers
  final TextEditingController _plantNameController = TextEditingController();
  final TextEditingController _plantSpeciesController = TextEditingController();
  final TextEditingController _wateringIntervalController = TextEditingController(text: "3");
  
  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs
  
  @override
  void dispose() {
    _deviceIdController.dispose();
    _plantNameController.dispose();
    _plantSpeciesController.dispose();
    _wateringIntervalController.dispose();
    _disconnectMqtt();
    super.dispose();
  }
  
  // Connect to MQTT server
  Future<void> _connectMqtt() async {
    setState(() {
      _isConnecting = true;
      _isSearching = false;
      _deviceFound = false;
    });
    
    final String deviceId = _deviceIdController.text.trim();
    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a device ID'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isConnecting = false;
      });
      return;
    }
    
    // Create MQTT client instance
    final client = MqttServerClient(_mqttServer, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    client.port = _mqttPort;
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    
    // Set authentication (if needed)
    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .startClean();
    
    if (_mqttUsername.isNotEmpty) {
      connMessage.authenticateAs(_mqttUsername, _mqttPassword);
    }
    
    client.connectionMessage = connMessage;
    
    try {
      await client.connect();
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to MQTT server'),
            backgroundColor: Color(0xFF4A8F3C),
          ),
        );
        
        // Subscribe to device topic
        final deviceId = _deviceIdController.text.trim();
        final topic = 'waterme/devices/$deviceId';
        print('Subscribing to topic: $topic');
        client.subscribe(topic, MqttQos.atLeastOnce);
        
        // Listen for messages
        client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
          for (final MqttReceivedMessage<MqttMessage> message in c) {
            final MqttPublishMessage pubMessage = message.payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(pubMessage.payload.message);
            print('Received message: ${message.topic}, content: $payload');
            
            // Parse JSON data
            try {
              final data = jsonDecode(payload);
              
              // Check if this is a message for the target device
              if (message.topic == topic) {
                setState(() {
                  _deviceFound = true;
                  _deviceData = data;
                  _isSearching = false;
                });
                print('Device found: $deviceId, data: $data');
              }
            } catch (e) {
              print('JSON parsing error: $e');
            }
          }
        });
        
        // Publish a query message, requesting device to respond
        final builder = MqttClientPayloadBuilder();
        builder.addString(jsonEncode({
          'action': 'query',
          'client_id': client.clientIdentifier
        }));
        client.publishMessage('waterme/commands/$deviceId', MqttQos.atLeastOnce, builder.payload!);
        print('Sent query command to: waterme/commands/$deviceId');
        
        setState(() {
          _client = client;
          _isConnected = true;
          _isConnecting = false;
          _isSearching = true;
        });
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to connect to MQTT server'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isConnecting = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isConnecting = false;
      });
    }
  }
  
  // Disconnect from MQTT
  void _disconnectMqtt() {
    _client?.disconnect();
    setState(() {
      _client = null;
      _isConnected = false;
      _isSearching = false;
      _deviceFound = false;
    });
  }
  
  // MQTT disconnection callback
  void _onDisconnected() {
    setState(() {
      _isConnected = false;
      _isSearching = false;
    });
  }
  
  // Register plant
  Future<void> _registerPlant() async {
    if (_plantNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a plant name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_wateringIntervalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter watering interval days'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Parse the interval value
    final intervalValue = int.tryParse(_wateringIntervalController.text);
    if (intervalValue == null || intervalValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number for watering interval'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      if (FirebaseService.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to log in to register a plant'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final userId = FirebaseService.currentUser!.uid;
      final deviceId = _deviceIdController.text.trim();
      
      // Randomly select a pixel-style plant image
      final randomImageIndex = Random().nextInt(PlantImages.getPlantImagesCount());
      final imagePath = PlantImages.getPlantImageByIndex(randomImageIndex);
      
      // Calculate next watering date
      final now = DateTime.now();
      final nextWatering = now.add(Duration(days: intervalValue));
      
      // Print debug info
      print('Registering plant...');
      print('User ID: $userId');
      print('Device ID: $deviceId');
      print('Plant name: ${_plantNameController.text}');
      print('Plant species: ${_plantSpeciesController.text}');
      print('Watering interval: ${intervalValue} days');
      
      // 1. First save device info
      await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .set({
        'deviceId': deviceId,
        'paired_at': FieldValue.serverTimestamp(),
        'last_seen': FieldValue.serverTimestamp(),
      });
      
      // 2. Then save plant info
      await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('plants')
          .add({
        'name': _plantNameController.text.trim(),
        'species': _plantSpeciesController.text.trim(),
        'device_id': deviceId,
        'image': imagePath,
        'last_watered': FieldValue.serverTimestamp(),
        'next_watering': Timestamp.fromDate(nextWatering),
        'watering_interval': intervalValue,
        'created_at': FieldValue.serverTimestamp(),
        'moisture': _deviceData?['moisture_pct'] ?? 0,
        'temperature': _deviceData?['temperature'] ?? 0,
      });
      
      // Clear input fields
      _plantNameController.clear();
      _plantSpeciesController.clear();
      _wateringIntervalController.text = "3"; // Reset to default value
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plant successfully added to your collection!'),
          backgroundColor: Color(0xFF4A8F3C),
        ),
      );
      
      setState(() {
        _deviceFound = false;
        _isSearching = false;
      });
      
    } catch (e) {
      print('Failed to register plant: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register plant: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Open plant registration form
  void _showPlantRegistrationForm() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: const BorderSide(color: Color(0xFF4A8F3C), width: 3),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF4A8F3C), width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Register New Plant',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5530),
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _plantNameController,
                  decoration: const InputDecoration(
                    labelText: 'Plant Name *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Color(0xFF4A8F3C), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _plantSpeciesController,
                  decoration: const InputDecoration(
                    labelText: 'Plant Species',
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Color(0xFF4A8F3C), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _wateringIntervalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Watering Interval (days) *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Color(0xFF4A8F3C), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _registerPlant().then((_) {
                          Navigator.of(dialogContext).pop();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A8F3C),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
                    'CONNECT TO SENSOR',
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
                
                // Device ID input area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: const Color(0xFF4A8F3C),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter your device ID',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C5530),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _deviceIdController,
                        decoration: const InputDecoration(
                          hintText: 'e.g.: waterme_1',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Color(0xFF4A8F3C),
                              width: 2,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                        ),
                        enabled: !_isConnecting && !_isSearching,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isConnecting || _isSearching ? null : _connectMqtt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A8F3C),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: _isConnecting
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                )
                              : const Text(
                                  'Connect & Search',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Search status area
                Expanded(
                  child: Center(
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
                      child: _buildStatusContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusContent() {
    if (_deviceFound) {
      // Device found, show device info
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Color(0xFF4A8F3C),
          ),
          const SizedBox(height: 20),
          Text(
            'Device found: ${_deviceIdController.text}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5530),
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (_deviceData != null) ...[
            Text(
              'Moisture: ${_deviceData!['moisture_pct']}%',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2C5530),
                fontFamily: 'monospace',
              ),
            ),
            Text(
              'Temperature: ${_deviceData!['temperature']}°C',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2C5530),
                fontFamily: 'monospace',
              ),
            ),
          ],
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _showPlantRegistrationForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A8F3C),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text(
              'Register New Plant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      );
    } else if (_isSearching) {
      // Searching for device
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 80,
            color: const Color(0xFF4A8F3C).withOpacity(0.7),
          ),
          const SizedBox(height: 20),
          const Text(
            'LOOKING FOR WATERME SENSORS...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5530),
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 30),
          const CircularProgressIndicator(
            color: Color(0xFF4A8F3C),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _disconnectMqtt,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text(
              'Cancel Search',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      );
    } else {
      // Initial state or search complete but no device found
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sensors,
            size: 80,
            color: const Color(0xFF4A8F3C).withOpacity(0.7),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ready to connect your WaterMe sensor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5530),
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter device ID and click "Connect & Search" button',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2C5530),
              fontFamily: 'monospace',
            ),
          ),
        ],
      );
    }
  }
}
