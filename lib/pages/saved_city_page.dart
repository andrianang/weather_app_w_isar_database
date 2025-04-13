import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../pages/search_page.dart';
import 'package:weather_app/services/database_service.dart';

class SavedCitiesPage extends StatefulWidget {
  final DatabaseService dbService;
  final WeatherService weatherService;
  
  const SavedCitiesPage(this.weatherService, this.dbService, {super.key});

  @override
  State<SavedCitiesPage> createState() => _SavedCitiesPageState();
}

class _SavedCitiesPageState extends State<SavedCitiesPage> {
  List <String> savedCities = [];
  Map<String, Weather> weatherData = {};

  Future<void> _loadCitites() async{
    final cities = await widget.dbService.getAllCities();
    setState(() {
      savedCities = cities.map((e) => e.cityName).toList();
    });
    for (var city in savedCities){
      await _fetchWeather(city);
    }
  }


  Future<void> _fetchWeather(String city) async {
    try {
      Weather weather = await widget.weatherService.getWeather(city);
      setState(() {
        weatherData[city] = weather;
      });
    } catch (e) {
      print("Error fetching weather for $city: $e");
    }
  }

  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/sunny.json';

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'assets/cloudy.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'assets/raining.json';
      case 'thunderstorm':
        return 'assets/thunderstorm.json';
      default:
        return 'assets/sunny.json';
    }
  }

  Future <void> _editCity(int index) async{
    String oldCity = savedCities[index];
    TextEditingController cityController = TextEditingController(text: oldCity);

    String? newCity = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit City"),
          content: TextField(
            controller: cityController,
            decoration: InputDecoration(
              labelText: "Enter new city name",
              border: OutlineInputBorder(),
            )
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, cityController.text),
              child: Text("Save"),
            ),
          ]
        );
      }
    );

    if (newCity != null && newCity.isNotEmpty && newCity != oldCity) {
      await widget.dbService.editCity(oldCity, newCity);
      setState(() {
        weatherData.remove(oldCity);
      });
      await _loadCitites();
    }
  }
  Future<void> _addCity(String city) async{
    await widget.dbService.addCity(city);
    await _loadCitites();
  }

  Future <void> _deleteCity(int index) async{
    final city = savedCities[index];
    await widget.dbService.deleteCity(city);
    setState(() {
      savedCities.removeAt(index);
      weatherData.remove(city);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCitites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Saved Cities")),
      body: savedCities.isEmpty
          ? Center(child: Text("No saved cities yet"))
          : Padding(
              padding: EdgeInsets.all(10),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two columns
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8, // Adjust for better layout
                ),
                itemCount: savedCities.length,
                itemBuilder: (context, index) {
                  String city = savedCities[index];
                  Weather? weather = weatherData[city];

                  return Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weather?.cityName ?? "Loading...",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Lottie.asset(getWeatherAnimation(weather?.mainCondition), height: 80),
                        Text(
                          weather != null ? '${weather.temperature.round()}°C' : "Loading...",
                          style: TextStyle(fontSize: 18),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editCity(index),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                               _deleteCity(index);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? newCity = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchPage()),
          );
          if (newCity != null && newCity.isNotEmpty) {
            _addCity(newCity);
          }
        },
        child: Icon(Icons.search),
      ),
    );
  }
}