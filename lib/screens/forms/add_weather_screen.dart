// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mspaa/providers/weather_provider.dart'; // Asegúrate de importar el WeatherProvider

class AddWeatherScreen extends StatefulWidget {
  const AddWeatherScreen({super.key});

  @override
  _AddWeatherScreenState createState() => _AddWeatherScreenState();
}

class _AddWeatherScreenState extends State<AddWeatherScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vientoController = TextEditingController();
  final TextEditingController _temperaturaController = TextEditingController();
  final TextEditingController _humedadController = TextEditingController();
  final TextEditingController _lluviaController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Acceder al WeatherProvider correctamente
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar Datos del Clima"),
      ),
      body: weatherProvider.isLoading
          ? const Center(child: CircularProgressIndicator())  // Muestra un cargador mientras se obtiene la información
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDatePicker(),
                    const SizedBox(height: 20),
                    _buildVientoField(),
                    const SizedBox(height: 20),
                    _buildTemperaturaField(),
                    const SizedBox(height: 20),
                    _buildHumedadField(),
                    const SizedBox(height: 20),
                    _buildLluviaField(),
                    const SizedBox(height: 20),
                    _buildSaveButton(weatherProvider),  // Pasa el provider al botón para que lo utilice
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: Text("Fecha: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}"),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (pickedDate != null) {
          setState(() {
            _selectedDate = pickedDate;
          });
        }
      },
    );
  }

  Widget _buildVientoField() {
    return TextFormField(
      controller: _vientoController,
      decoration: const InputDecoration(
        labelText: "Velocidad del Viento (m/s)",
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, ingresa la velocidad del viento.';
        }
        return null;
      },
    );
  }

  Widget _buildTemperaturaField() {
    return TextFormField(
      controller: _temperaturaController,
      decoration: const InputDecoration(
        labelText: "Temperatura (°C)",
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, ingresa la temperatura.';
        }
        return null;
      },
    );
  }

  Widget _buildHumedadField() {
    return TextFormField(
      controller: _humedadController,
      decoration: const InputDecoration(
        labelText: "Humedad (%)",
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, ingresa la humedad.';
        }
        return null;
      },
    );
  }

  Widget _buildLluviaField() {
    return TextFormField(
      controller: _lluviaController,
      decoration: const InputDecoration(
        labelText: "Cantidad de Lluvia (mm)",
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, ingresa la cantidad de lluvia.';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton(WeatherProvider weatherProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            // Crear el objeto de datos del clima
            Map<String, dynamic> weatherData = {
              "cl_fecha": DateFormat("yyyy-MM-dd").format(_selectedDate),
              "cl_viento": double.tryParse(_vientoController.text) ?? 0.0,
              "cl_temp": double.tryParse(_temperaturaController.text) ?? 0.0,
              "cl_hume": double.tryParse(_humedadController.text) ?? 0.0,
              "cl_lluvia": double.tryParse(_lluviaController.text) ?? 0.0,
            };

            // Llamar al provider para guardar los datos del clima
            bool success = await weatherProvider.addWeatherData(weatherData);

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Datos del clima guardados con éxito")));
              context.go('/home'); // Regresar a la pantalla anterior
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar los datos del clima")));
            }
          }
        },
        child: const Text("Guardar Datos"),
      ),
    );
  }
}
