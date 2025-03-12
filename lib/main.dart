import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:weather_icons/weather_icons.dart';

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
      themeMode: ThemeMode.system,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardTheme(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue[800],
        scaffoldBackgroundColor: Colors.grey[900],
        cardTheme: CardTheme(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
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
  String _humidity = '';
  String _windSpeed = '';
  List<dynamic> _forecast = [];
  String _errorMessage = '';
  bool _isDarkMode = false;
  bool _isLoading = false;

  Future<void> _fetchWeather(String city) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('https://weatheria-wlco.onrender.com/?city=$city&format=json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weather = data['weather']['weather'][0]['description'];
          _temp = "${data['weather']['main']['temp']}°C";
          _humidity = "Humidity: ${data['weather']['main']['humidity']}%";
          _windSpeed = "Wind: ${data['weather']['wind']['speed']} km/h";
          _forecast = [];
          _errorMessage = '';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load weather data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLocationWeather() async {
    setState(() {
      _isLoading = true;
    });
    try {
      Position position = await _determinePosition();
      final response = await http.get(
        Uri.parse('https://weatheria-wlco.onrender.com/?lat=${position.latitude}&lon=${position.longitude}&format=json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weather = data['weather']['weather'][0]['description'];
          _temp = "${data['weather']['main']['temp']}°C";
          _humidity = "Humidity: ${data['weather']['main']['humidity']}%";
          _windSpeed = "Wind: ${data['weather']['wind']['speed']} km/h";
          _forecast = [];
          _errorMessage = '';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch location weather: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, please enable them in settings.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return WeatherIcons.day_sunny;
      case 'clouds':
        return WeatherIcons.cloudy;
      case 'rain':
        return WeatherIcons.rain;
      case 'snow':
        return WeatherIcons.snow;
      case 'thunderstorm':
        return WeatherIcons.thunderstorm;
      default:
        return WeatherIcons.day_sunny;
    }
  }

  BoxDecoration _weatherBackground() {
    if (_weather.contains("Rain")) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[400]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    } else if (_weather.contains("Sunny")) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[800]!, Colors.yellow[400]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    } else {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[800]!, Colors.grey[400]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[800]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Switch(
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: _weatherBackground(),
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
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 20),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _fetchLocationWeather,
                    icon: Icon(Icons.location_on),
                    label: Text('Use Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : _weather.isNotEmpty
                      ? Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: Colors.white.withOpacity(0.2),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  _getWeatherIcon(_weather),
                                  size: 60,
                                  color: Colors.orange,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  _weather,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                SizedBox(height: 10),
                                Text(_temp, style: TextStyle(fontSize: 20, color: Colors.white)),
                                SizedBox(height: 10),
                                Text(_humidity, style: TextStyle(fontSize: 16, color: Colors.white)),
                                Text(_windSpeed, style: TextStyle(fontSize: 16, color: Colors.white)),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(), // Fallback widget
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
}