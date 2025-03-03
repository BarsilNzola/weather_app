import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      themeMode: ThemeMode.system, // Auto-detect system theme
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _cityController = TextEditingController();
  String _weather = 'Enter a city or use location';
  String _temp = '';
  String _icon = '';
  String _humidity = '';
  String _windSpeed = '';
  List<dynamic> _forecast = [];
  String _errorMessage = '';
  bool _isDarkMode = false;

  Future<void> _fetchWeather(String city) async {
    final response = await http.get(
      Uri.parse('https://your-api-url/weather?city=$city'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _weather = data['weather'];
        _temp = "${data['temperature']}°C";
        _icon = data['icon'];
        _humidity = "Humidity: ${data['humidity']}%";
        _windSpeed = "Wind: ${data['wind_speed']} km/h";
        _forecast = data['forecast'];
        _errorMessage = '';
      });
    } else {
      setState(() {
        _weather = '';
        _temp = '';
        _icon = '';
        _humidity = '';
        _windSpeed = '';
        _forecast = [];
        _errorMessage = 'Failed to load weather data';
      });
    }
  }

  Future<void> _fetchLocationWeather() async {
    Position position = await _determinePosition();
    final response = await http.get(
      Uri.parse(
          'https://your-api-url/weather?lat=${position.latitude}&lon=${position.longitude}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _weather = data['weather'];
        _temp = "${data['temperature']}°C";
        _icon = data['icon'];
        _humidity = "Humidity: ${data['humidity']}%";
        _windSpeed = "Wind: ${data['wind_speed']} km/h";
        _forecast = data['forecast'];
        _errorMessage = '';
      });
    } else {
      setState(() {
        _errorMessage = 'Failed to fetch location weather';
      });
    }
  }

  Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if GPS is enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  // Check location permission
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, please enable them in settings.');
  }

  // Get location using the new 'settings' parameter
  return await Geolocator.getCurrentPosition(
    locationSettings: LocationSettings( // ✅ Correct named parameter
      accuracy: LocationAccuracy.high,  // High accuracy
      distanceFilter: 10,  // Update if user moves 10 meters
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          Switch(
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
                ThemeMode mode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_weatherBackground()),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'Enter City',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      String city = _cityController.text;
                      if (city.isNotEmpty) {
                        _fetchWeather(city);
                      }
                    },
                    child: Text('Search'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _fetchLocationWeather,
                    icon: Icon(Icons.location_on),
                    label: Text('Use Location'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: TextStyle(color: Colors.red)),
              if (_weather.isNotEmpty)
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(_icon, style: TextStyle(fontSize: 40)),
                        SizedBox(height: 10),
                        Text(
                          _weather,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(_temp, style: TextStyle(fontSize: 20)),
                        Text(_humidity),
                        Text(_windSpeed),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 20),
              if (_forecast.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _forecast.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Text(_forecast[index]['icon'], style: TextStyle(fontSize: 20)),
                              Text(_forecast[index]['day']),
                              Text("${_forecast[index]['temp']}°C"),
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
    );
  }

  String _weatherBackground() {
    if (_weather.contains("Rain")) return "assets/rainy.jpg";
    if (_weather.contains("Sunny")) return "assets/sunny.jpg";
    return "assets/cloudy.jpg";
  }
}
