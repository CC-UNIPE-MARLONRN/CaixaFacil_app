import 'package:caixafacil_app/controller/agencia_controller.dart';
import 'package:caixafacil_app/model/agencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:caixafacil_app/service/geocoding_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class ListarAgencias extends StatefulWidget {
  const ListarAgencias({super.key});

  @override
  State<ListarAgencias> createState() => _ListarAgenciasState();
}

class _ListarAgenciasState extends State<ListarAgencias> {
  // Dark blue theme color (used across top layout, FABs, markers, bottom sheets)
  static const Color _darkBlue = Color(0xFF003A63);

  final _controller = AgenciaController();
  late final MapController _mapController;
  late final TextEditingController _searchCtrl;
  final List<Marker> _markers = [];
  final LatLng _initialCameraPosition = LatLng(-23.55052, -46.633308);
  // track current center (updates when the map moves)
  late LatLng _currentCenter;
  bool _examplesGenerated = false;
  final List<Agencia> _generatedAgencias = [];
  // store last searched coordinates (so "Recomendar" can use the searched address)
  LatLng? _lastSearchLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchCtrl = TextEditingController();
    _currentCenter = _initialCameraPosition;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo/icon.png', height: 36, width: 36),
            const SizedBox(width: 10),
            const Text('Agencias Caixa Fácil'),
          ],
        ),
        centerTitle: false,
        foregroundColor: Colors.white,
        backgroundColor: _darkBlue,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _initialCameraPosition,
              zoom: 14,
              minZoom: 5,
              maxZoom: 18,
              onPositionChanged: (pos, hasGesture) {
                if (pos.center != null) {
                  _currentCenter = pos.center!;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(
                  0xBF003A63,
                ), // dark blue with some transparency
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Insira o endereço',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _searchAndShow(),
                    icon: const Icon(Icons.search, color: Colors.white),
                    tooltip: 'Buscar',
                  ),
                ],
              ),
            ),
          ),
          // [NOVO] Botão de Localização no canto inferior esquerdo (mantido apenas um)
          Positioned(
            bottom: 24,
            left: 16,
            child: Material(
              color: Colors.white, // Fundo branco
              elevation: 4.0,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _goToMyLocation, // Reutiliza a função
                borderRadius: BorderRadius.circular(28.0),
                child: Container(
                  width: 56, // Tamanho padrão de FAB
                  height: 56,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.my_location,
                    color: _darkBlue, // Ícone azul escuro
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Future<void> _goToMyLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Serviço desativado. Ative nas configurações.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage('Permissão negada');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showMessage('Permissão negada permanentemente.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final p = LatLng(pos.latitude, pos.longitude);
      _mapController.move(p, 15);
      _markers.clear();
      _markers.add(
        Marker(
          point: p,
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                color: _darkBlue,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ),
      );
      setState(() {});
      final list = await _controller.searchByAddressOrCoords(
        '${pos.latitude},${pos.longitude}',
        maxDistanceKm: 5.0,
      );
      if (list != null) {
        for (var a in list) {
          _markers.add(
            Marker(
              point: LatLng(a.latitude, a.longitude),
              builder: (ctx) => GestureDetector(
                onTap: () => _onAgenciaTap(a),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: _darkBlue,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        setState(() {});
      }
    } catch (e) {
      _showMessage('Erro: $e');
    }
  }

  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end, // Alinha FABs à direita
      children: [
        FloatingActionButton.extended(
          heroTag: 'seed',
          backgroundColor: _darkBlue,
          icon: const Icon(Icons.download_rounded, color: Colors.white),
          label: const Text(
            'Gerar Exemplos',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () async {
            await _generateExamples(20);
            setState(() {
              _examplesGenerated = true;
            });
          },
        ),
        const SizedBox(height: 8),
        if (_examplesGenerated)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FloatingActionButton.extended(
              heroTag: 'show',
              backgroundColor: Colors.white,
              icon: const Icon(Icons.list, color: _darkBlue),
              label: const Text(
                'Exibir Agências',
                style: TextStyle(color: _darkBlue),
              ),
              onPressed: () => _showCreatedAgencias(),
            ),
          ),
        FloatingActionButton.extended(
          heroTag: 'recommend',
          backgroundColor: _darkBlue,
          icon: const Icon(Icons.recommend, color: Colors.white),
          label: const Text(
            'Recomendar',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () => _recommendNow(),
        ),
      ],
    );
  }

  /// Generate [count] example "Caixa Econômica" agencies around the
  /// current map center and display them on the map.
  Future<void> _generateExamples(int count) async {
    final center = _currentCenter;
    final rnd = Random(DateTime.now().millisecondsSinceEpoch);
    final servicesPool = [
      'recebimento',
      'pagamento',
      'caixa',
      'conta bancaria',
      'saque',
      'depósito',
    ];
    final nomesPadrao = [
      'Caixa Centro',
      'Caixa Bairro',
      'Caixa Terminal',
      'Caixa Loteria São Paulo',
      'Caixa Rio Rua Sul',
      'Caixa Av. Central',
      'Caixa Shopping',
      'Caixa Estação',
      'Caixa São João',
      'Caixa São Paulo',
    ];

    final newMarkers = <Marker>[];
    const pi = 3.1415926535;
    final centerLatRad = center.latitude * pi / 180.0;
    final cosLat = (111.0 * cos(centerLatRad));

    for (var i = 0; i < count; i++) {
      final d = rnd.nextDouble() * 2.0; // up to ~2 km
      final angle = rnd.nextDouble() * 2 * pi;
      final dLat = (d / 111.0) * sin(angle);
      final dLon = (d / cosLat) * cos(angle);

      // generate a small random set of services per agency
      final svcCount = 2 + rnd.nextInt(3); // 2..4 services
      final svcSet = <String>{};
      for (var s = 0; s < svcCount; s++) {
        svcSet.add(servicesPool[rnd.nextInt(servicesPool.length)]);
      }

      final nm =
          nomesPadrao[i % nomesPadrao.length] +
          (i >= nomesPadrao.length ? ' ${i + 1}' : '');
      final a = Agencia(
        nome: nm,
        endereco: 'Avenida Principal, ${(100 + i)}',
        latitude: center.latitude + dLat,
        longitude: center.longitude + dLon,
        ocupacaoAtual: rnd.nextInt(25),
        capacidade: 20 + rnd.nextInt(40),
        horario: '08:00-16:00',
        tipoServico: svcSet.join(', '),
      );

      _generatedAgencias.add(a);
      newMarkers.add(
        Marker(
          point: LatLng(a.latitude, a.longitude),
          builder: (ctx) => GestureDetector(
            onTap: () => _onAgenciaTap(a),
            child: Container(
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: const BoxDecoration(
                  color: _darkBlue,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.account_balance, color: Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    _markers.addAll(newMarkers);
    if (mounted) setState(() {});
  }

  double _estimateWaitMinutes(Agencia a) {
    // simple heuristic: average service time per person is 4 minutes
    const double avgMinutesPerPerson = 4.0;
    // estimate number of tellers from capacity (approx 1 teller per 15-20 cap)
    int tellers = (a.capacidade / 15).round();
    if (tellers < 1) tellers = 1;
    final wait = (a.ocupacaoAtual * avgMinutesPerPerson) / tellers;
    return wait;
  }

  Future<void> _showCreatedAgencias() async {
    final list = _generatedAgencias.isNotEmpty
        ? _generatedAgencias
        : await _controller.findAll() ?? [];
    if (list.isEmpty) {
      _showMessage('Nenhuma agência cadastrada');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _darkBlue,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.all(8),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white24),
          itemBuilder: (context, index) {
            final a = list[index];
            final wait = _estimateWaitMinutes(a);
            return ListTile(
              title: Text(a.nome, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                '${a.endereco}\nServiços: ${a.tipoServico}',
                style: const TextStyle(color: Colors.white70),
              ),
              isThreeLine: true,
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${a.ocupacaoAtual}/${a.capacidade}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${wait.toStringAsFixed(0)} min',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _mapController.move(LatLng(a.latitude, a.longitude), 16);
                _onAgenciaTap(a);
              },
            );
          },
        ),
      ),
    );
  }

  void _openSearchDialog() {
    final input = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buscar por endereço'),
        content: TextField(
          controller: input,
          decoration: const InputDecoration(
            hintText: 'ex: -23.55052,-46.633308',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final q = input.text.trim();
              Navigator.of(ctx).pop();
              if (q.isEmpty) return;
              double? lat, lon;
              final parts = q.split(',');
              if (parts.length == 2) {
                lat = double.tryParse(parts[0].trim());
                lon = double.tryParse(parts[1].trim());
              }
              if (lat == null || lon == null) {
                final geo = await GeocodingService.geocode(q);
                if (geo == null) {
                  _showMessage('Não encontrado');
                  return;
                }
                lat = geo['lat'];
                lon = geo['lon'];
              }
              if (lat == null || lon == null) return;
              final list = await _controller.searchByAddressOrCoords(
                '$lat,$lon',
                maxDistanceKm: 10.0,
              );
              if (list == null || list.isEmpty) {
                _showMessage('Nenhuma agência');
                return;
              }
              // remember last search location so Recommendation can use it
              _lastSearchLocation = LatLng(lat, lon);
              _showBottomAgencias(list, _lastSearchLocation!);
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  void _showBottomAgencias(List<Agencia> agencias, LatLng origin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _darkBlue,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.all(8),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: agencias.length,
          itemBuilder: (context, index) {
            final a = agencias[index];
            final dist =
                Geolocator.distanceBetween(
                  origin.latitude,
                  origin.longitude,
                  a.latitude,
                  a.longitude,
                ) /
                1000;
            return ListTile(
              title: Text(a.nome, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                a.endereco,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Text(
                '${dist.toStringAsFixed(1)} km',
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _openMapsTo(a.latitude, a.longitude);
              },
            );
          },
        ),
      ),
    );
  }

  void _openMapsTo(double lat, double lon) async {
    // URL correta para abrir o Google Maps
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('Não foi possível abrir o mapa');
      }
    } catch (e) {
      _showMessage('Erro: $e');
    }
  }

  Future<void> _recommendNow() async {
    // Determine origin: prefer last searched location, else device location, else map center
    LatLng origin = _lastSearchLocation ?? _currentCenter;
    try {
      if (_lastSearchLocation == null) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        origin = LatLng(pos.latitude, pos.longitude);
      }
    } catch (_) {
      // keep origin as _lastSearchLocation or _currentCenter
    }

    // Prefer generated agencies (in-memory). Fallback to DB if none.
    final all = _generatedAgencias.isNotEmpty
        ? _generatedAgencias
        : (await _controller.findAll() ?? []);
    if (all.isEmpty) {
      _showMessage('Nenhuma agência disponível');
      return;
    }

    // Consider all agencies (don't filter by name); we'll pick those near origin
    final candidates = all.toList();
    List<Agencia> within = [];
    for (var a in candidates) {
      final dist = a.distanciaPara(origin.latitude, origin.longitude);
      if (dist <= 20.0) within.add(a);
    }
    if (within.isEmpty) {
      // fallback: use any agency within 20 km
      for (var a in all) {
        if (a.distanciaPara(origin.latitude, origin.longitude) <= 20.0) {
          within.add(a);
        }
      }
    }
    if (within.isEmpty) {
      _showMessage('Nenhuma agência encontrada nas proximidades');
      return;
    }
    // sort by estimated wait (ascending) then distance
    within.sort((a, b) {
      final wa = _estimateWaitMinutes(a);
      final wb = _estimateWaitMinutes(b);
      if (wa == wb) {
        return a
            .distanciaPara(origin.latitude, origin.longitude)
            .compareTo(b.distanciaPara(origin.latitude, origin.longitude));
      }
      return wa.compareTo(wb);
    });
    final rec = within.first;
    final p = LatLng(rec.latitude, rec.longitude);
    _mapController.move(p, 16);
    // highlight recommended agency (larger blue circular marker)
    _markers.add(
      Marker(
        point: p,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              color: _darkBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.location_city,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
    setState(() {});
    // open the agency detail bottom sheet (same as tapping the marker)
    _onAgenciaTap(rec);
  }

  void _showMessage(String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchAndShow() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    double? lat, lon;
    final parts = q.split(',');
    if (parts.length == 2) {
      lat = double.tryParse(parts[0].trim());
      lon = double.tryParse(parts[1].trim());
    }
    if (lat == null || lon == null) {
      final geo = await GeocodingService.geocode(q);
      if (geo == null) {
        _showMessage('Endereço não encontrado');
        return;
      }
      lat = geo['lat'];
      lon = geo['lon'];
    }
    if (lat == null || lon == null) return;
    final p = LatLng(lat, lon);
    _mapController.move(p, 15);
    // remember last search location so recommendation uses this origin
    _lastSearchLocation = p;
    _markers.clear();
    _markers.add(
      Marker(
        point: p,
        builder: (ctx) => const Icon(Icons.location_on, color: Colors.red),
      ),
    );
    final list = await _controller.searchByAddressOrCoords(
      '$lat,$lon',
      maxDistanceKm: 10.0,
    );
    if (list == null || list.isEmpty) {
      setState(() {});
      _showMessage('Nenhuma encontrada');
      return;
    }
    for (var a in list) {
      _markers.add(
        Marker(
          point: LatLng(a.latitude, a.longitude),
          builder: (ctx) => GestureDetector(
            onTap: () => _onAgenciaTap(a),
            child: Container(
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: const BoxDecoration(
                  color: _darkBlue,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.account_balance, color: Colors.white),
              ),
            ),
          ),
        ),
      );
    }
    setState(() {});
    _showBottomAgencias(list, p);
  }

  // [MODIFICADO] Adicionada imagem ao lado dos detalhes
  void _onAgenciaTap(Agencia a) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _darkBlue, // dark blue theme
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem da Agência
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    'https://cdn.imgbin.com/1/19/2/imgbin-caixa-econ-mica-federal-fundo-de-garantia-do-tempo-de-servi-o-federal-savings-bank-mirage-2000-KTPD9W998r5Rt4xUQWTCC6a10.jpg',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    // Mostra um ícone de erro se a imagem falhar
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.white24,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Detalhes da Agência
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Endereço: ${a.endereco}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Serviços: ${a.tipoServico}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Ocupação: ${a.ocupacaoAtual}/${a.capacidade}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Tempo estimado: ${_estimateWaitMinutes(a).toStringAsFixed(0)} min',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Botões
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _darkBlue,
                  ),
                  onPressed: () => _openMapsTo(a.latitude, a.longitude),
                  icon: const Icon(Icons.directions),
                  label: const Text('Ir'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
