import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PROS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SinglePage(),
    );
  }
}

class SinglePage extends StatefulWidget {
  const SinglePage({super.key});

  @override
  _SinglePageState createState() => _SinglePageState();
}

class _SinglePageState extends State<SinglePage> {
  final List<List<double>> _signalData = List.generate(
      5,
      (_) => List<double>.filled(256, 0.0,
          growable: true)); // 256 points for 1 second
  late final Timer _signalTimer;
  late List<double> _eegData = []; // EEG (Column 2) - Brain
  late List<double> _eeg1Data = []; // EEG 1 (Column 3) - Breathing
  late List<double> _ekgData = []; // EKG (Column 4) - Heart
  late List<double> _eogData = []; // EOG (Column 5) - Eye
  late List<double> _emgData = []; // EMG (Column 6) - Muscle
  int _currentIndex = 0; // Index to track the current data value

  int updates = 0;
  double _stressLevel =
      50.0; // Dummy value for stress level, ranges from 0 to 100

  @override
  void initState() {
    super.initState();
    _loadData().then((_) {
      _signalTimer = Timer.periodic(const Duration(milliseconds: 4), (_) {
        updates++;
        if (updates % 256 == 0) {
          print('1 second of data streamed');
        }
        setState(() {
          if (_eegData.isNotEmpty) {
            _updateSignal(_signalData[0], _eegData); // Brain (EEG)
            _updateSignal(_signalData[1], _eogData); // Eye (EOG)
            _updateSignal(_signalData[2], _emgData); // Muscle (EMG)
            _updateSignal(_signalData[3], _ekgData); // Heart (EKG)
            _updateSignal(_signalData[4], _eeg1Data); // Breathing (EEG1)
          }
          // Gradually increase stress level with smaller increments for a smoother transition
          _stressLevel += 0.05; // Gradual increase
          if (_stressLevel >= 100)
            _stressLevel = 0; // Reset after reaching 100%
        });
      });
    });
  }

  Future<void> _loadData() async {
    try {
      final csvData = await rootBundle.loadString('assets/data.csv');
      final lines = csvData.split('\n');

      // Process each line, ensuring valid data
      for (var line in lines.skip(1)) {
        // Skip header row
        if (line.trim().isNotEmpty) {
          final values = line.split(',');
          if (values.length > 5) {
            _eegData.add(double.tryParse(values[1]) ?? 0.0); // EEG (Column 2)
            _eeg1Data
                .add(double.tryParse(values[2]) ?? 0.0); // EEG 1 (Column 3)
            _ekgData.add(double.tryParse(values[3]) ?? 0.0); // EKG (Column 4)
            _eogData.add(double.tryParse(values[4]) ?? 0.0); // EOG (Column 5)
            _emgData.add(double.tryParse(values[5]) ?? 0.0); // EMG (Column 6)
          }
        }
      }

      // Debug: Print a sample of the data
      print("Sample EEG Data: ${_eegData.take(10)}");
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  void _updateSignal(List<double> signal, List<double> source) {
    signal.removeAt(0); // Remove the oldest value
    signal.add(_normalize(
        source[_currentIndex],
        signal == _signalData[0] ||
            signal == _signalData[4])); // Normalize and add next value
    _currentIndex = (_currentIndex + 1) % source.length; // Loop through data
  }

  double _normalize(double value, bool isEEG) {
    const scaleEEG = 30.0; // EEG signals scale
    const scaleOther = 100.0; // Other signals scale
    final scale = isEEG ? scaleEEG : scaleOther;
    return (value / scale) * 15; // Normalize for display height
  }

  @override
  void dispose() {
    _signalTimer.cancel();
    super.dispose();
  }

  double _calculateStressPosition() {
    const maxLevel = 100.0;
    const barHeight = 350.0;
    return (_stressLevel / maxLevel) * barHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROS'),
        actions: [
          Icon(
            Icons.bluetooth_connected,
            color: Colors.green,
          ),
          const SizedBox(width: 10),
          const Icon(Icons.signal_cellular_alt, color: Colors.green),
          const SizedBox(width: 16),
          Row(
            children: const [
              Icon(Icons.battery_full, color: Colors.blue),
              Text('75%', style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Stress Level with Moving Indicator
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 60), // Move everything down
              child: Column(
                children: [
                  // Title Text - Stress Level
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 20), // Padding between title and bar
                    child: const Text(
                      'Stress Level',
                      style: TextStyle(
                        fontSize: 24, // Large title size
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Text color
                      ),
                    ),
                  ),
                  // Stress Level Bar (Gradient bar below the title)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Gradient Bar
                      Container(
                        width: 30,
                        height: 350,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.green,
                              Colors.yellow,
                              Colors.orange,
                              Colors.red
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      // Moving Indicator
                      Positioned(
                        bottom: _calculateStressPosition(),
                        child: Container(
                          width: 40,
                          height: 2,
                          color: Colors.black,
                        ),
                      ),
                      // Stress Level Percentage Text
                      Positioned(
                        bottom: _calculateStressPosition() - 30,
                        child: Text(
                          '${_stressLevel.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black),
                        ),
                      ),
                      // Static Threshold Indicator (75%)
                      Positioned(
                        bottom: (75 / 100) * 350, // 75% of the bar height
                        child: Container(
                          width: 50,
                          height: 2,
                          color: Colors
                              .yellow, // Color for the threshold indicator
                        ),
                      ),
                      // Label for the threshold (optional)
                      Positioned(
                        bottom: (75 / 100) * 350 -
                            10, // Adjust to place the label correctly
                        left: 40,
                        child: const Text(
                          'Dangerous Threshold',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Divider
          Container(width: 1, color: Colors.grey),
          // Right Side: Icons with Signals
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 55.0, left: 5.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSignalRow('assets/brain.png', _signalData[0],
                      const Color(0xFF1E88E5)), // Blue
                  const SizedBox(height: 40),
                  _buildSignalRow('assets/eye.png', _signalData[1],
                      const Color(0xFF8E24AA)), // Purple
                  const SizedBox(height: 40),
                  _buildSignalRow('assets/muscle.png', _signalData[2],
                      const Color(0xFFFB8C00)), // Orange
                  const SizedBox(height: 40),
                  _buildSignalRow('assets/heart.png', _signalData[3],
                      const Color(0xFFD32F2F)), // Red
                  const SizedBox(height: 40),
                  _buildSignalRow('assets/breath.png', _signalData[4],
                      const Color(0xFF43A047)), // Green
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Main Page',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_page),
            label: 'Contact',
          ),
        ],
      ),
    );
  }

  Widget _buildSignalRow(String iconPath, List<double> signal, Color color) {
    return Row(
      children: [
        Image.asset(iconPath, height: 40, width: 40),
        const SizedBox(width: 10),
        _buildSignal(signal, color),
      ],
    );
  }

  Widget _buildSignal(List<double> signal, Color color) {
    return SizedBox(
      height: 40, // Match PNG height
      width: 100, // Wider for signal
      child: CustomPaint(
        painter: SignalPainter(signal, color),
      ),
    );
  }
}

class SignalPainter extends CustomPainter {
  final List<double> signal;
  final Color color;

  SignalPainter(this.signal, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < signal.length; i++) {
      final x = i * size.width / signal.length; // Map x to signal width
      final y = size.height / 2 - signal[i]; // Adjust scaling
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
