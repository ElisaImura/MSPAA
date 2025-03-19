// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mspaa/providers/calendar_provider.dart';
import 'package:mspaa/screens/views/act_detail_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:weather_icons/weather_icons.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _mostrarTodas = false;
  bool _isFirstLoad = true; // Variable para evitar múltiples cargas innecesarias

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.utc(_focusedDay.year, _focusedDay.month, _focusedDay.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_isFirstLoad) {
      _isFirstLoad = false;

      // ✅ Asegura que `fetchData()` se ejecute después de que el widget se haya construido
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchData();
      });
    }
  }

  void _fetchData() async {
    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
    await calendarProvider.fetchData();

    if (mounted) {
      setState(() {
        _selectedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      });
    }
  }

  void _navigateToActivityDetail(Map<String, dynamic> actividad) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(actividad: actividad),
      ),
    );

    if (result == true) {
      if (mounted) {
        _fetchData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<CalendarProvider>(context);

    return Scaffold(
      body: calendarProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  locale: 'es_ES',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  eventLoader: (day) {
                    DateTime fechaNormalizada = DateTime.utc(day.year, day.month, day.day);
                    return calendarProvider.events[fechaNormalizada] ?? [];
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (mounted) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _mostrarTodas = false;
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (mounted) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF649966).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF649966),
                      shape: BoxShape.circle,
                    ),
                    markersAlignment: Alignment.bottomCenter,
                    markersMaxCount: 3,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
                _buildWeatherSection(calendarProvider), // Sección de clima
                Expanded(child: _buildEventList(calendarProvider)), // Lista de actividades
              ],
            ),
    );
  }

  Widget _buildWeatherSection(CalendarProvider calendarProvider) {
    if (_selectedDay == null) {
      return const SizedBox();
    }

    DateTime fechaNormalizada = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final clima = calendarProvider.weather[fechaNormalizada];

    if (clima == null) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color.fromARGB(255, 202, 221, 192), // Fondo celeste suave
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildWeatherItem('${clima['cl_viento']} m/s', WeatherIcons.windy),
          _buildWeatherItem('${clima['cl_temp']} °C', WeatherIcons.thermometer),
          _buildWeatherItem('${clima['cl_hume']}%', WeatherIcons.humidity),
          _buildWeatherItem('${clima['cl_lluvia']} mm', WeatherIcons.rain),
        ],
      ),
    );
  }

  Widget _buildWeatherItem(String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color.fromARGB(255, 19, 51, 20)), // Íconos pequeños
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)), // Texto pequeño y claro
      ],
    );
  }

  Widget _buildEventList(CalendarProvider calendarProvider) {
    if (_selectedDay == null) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: Text("No hay actividades para este día.", style: TextStyle(fontSize: 16))),
      );
    }

    DateTime fechaNormalizada = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final eventos = calendarProvider.events[fechaNormalizada] ?? [];

    if (eventos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: Text("No hay actividades para este día.", style: TextStyle(fontSize: 16))),
      );
    }

    final mostrarEventos = _mostrarTodas ? eventos : eventos.take(3).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: mostrarEventos.length + (eventos.length > 3 ? 1 : 0), // Mostrar "más" si hay más de 3 eventos
      itemBuilder: (context, index) {
        if (index < mostrarEventos.length) {
          final actividad = mostrarEventos[index];
          String tipoActividad = actividad['tipo_actividad']?['tpAct_nombre'] ?? "Sin tipo";
          return ListTile(
            leading: const Icon(Icons.event, color: Color.fromARGB(255, 45, 97, 47)),
            title: Text(tipoActividad),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => _navigateToActivityDetail(actividad),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: TextButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _mostrarTodas = !_mostrarTodas;
                  });
                }
              },
              child: Text(_mostrarTodas ? "Mostrar menos" : "Mostrar más"),
            ),
          );
        }
      },
    );
  }
}