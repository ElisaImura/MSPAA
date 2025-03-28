// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mspaa/providers/weather_provider.dart';
import 'package:mspaa/screens/forms/edit/edit_weather_screen.dart';
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
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    await calendarProvider.fetchData();
    await weatherProvider.fetchWeatherData();

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
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      body: calendarProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: TableCalendar(
                      locale: 'es_ES',
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarFormat: _calendarFormat,
                      eventLoader: (day) {
                        final fecha = DateTime.utc(day.year, day.month, day.day);
                        return calendarProvider.events[fecha] ?? [];
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          _mostrarTodas = false;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
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
                  ),
                ];
              },
              body: Column(
                children: [
                  _buildWeatherSection(calendarProvider, weatherProvider),
                  _buildEventList(calendarProvider),
                ],
              ),
            ),
    );
  }

  Widget _buildWeatherSection(CalendarProvider calendarProvider, WeatherProvider weatherProvider) {
    if (_selectedDay == null) return const SizedBox();

    DateTime fechaNormalizada = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final climas = weatherProvider.weatherPorFecha[fechaNormalizada] ?? [];

    if (climas.isEmpty) return const SizedBox();

    final PageController controller = PageController();
    int currentIndex = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Stack(
          children: [
            SizedBox(
              height: 110,
              width: double.infinity,
              child: PageView.builder(
                controller: controller,
                itemCount: climas.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final clima = climas[index];
                  final loteNombre = clima['lote']?['lot_nombre'] ?? 'Lote desconocido';

                  return GestureDetector(
                    onTap: () => _mostrarDialogoClima(context, fechaNormalizada, clima),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color.fromARGB(255, 202, 221, 192),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Clima del lote $loteNombre',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildWeatherItem('${clima['cl_viento']} m/s', WeatherIcons.windy),
                              _buildWeatherItem('${clima['cl_temp']} °C', WeatherIcons.thermometer),
                              _buildWeatherItem('${clima['cl_hume']}%', WeatherIcons.humidity),
                              _buildWeatherItem('${clima['cl_lluvia']} mm', WeatherIcons.rain),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (currentIndex > 0)
              const Positioned(
                left: 8,
                top: 40,
                child: Icon(Icons.chevron_left, size: 32, color: Colors.black45),
              ),
            if (currentIndex < climas.length - 1)
              const Positioned(
                right: 8,
                top: 40,
                child: Icon(Icons.chevron_right, size: 32, color: Colors.black45),
              ),
          ],
        );
      },
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

  void _mostrarDialogoClima(BuildContext context, DateTime fecha, Map<String, dynamic> clima) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.cloud, color: Color(0xFF49784F)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Opciones del Clima (${clima["lote"]?["lot_nombre"] ?? "Lote"})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '¿Qué deseas hacer con los datos climáticos de este día?',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text('Editar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditWeatherScreen(weather: clima),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text('Eliminar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final provider = Provider.of<WeatherProvider>(context, listen: false);
                  final eliminado = await provider.deleteWeather(clima['cl_id']);
                  Navigator.of(context).pop();
                  if (eliminado) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Datos del clima eliminados')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al eliminar clima')),
                    );
                  }
                  _fetchData();
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    );
  }

}