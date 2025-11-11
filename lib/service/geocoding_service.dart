import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  /// Usa o Nominatim (OpenStreetMap) para geocodificar um texto de endereço
  /// retorna um Map {'lat': double, 'lon': double} ou null se não encontrado.
  static Future<Map<String, double>?> geocode(String query) async {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search')
        .replace(queryParameters: {'q': query, 'format': 'json', 'limit': '1'});
    try {
      final res = await http.get(uri, headers: {'User-Agent': 'caixafacil_app/1.0'});
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as List<dynamic>;
      if (data.isEmpty) return null;
      final first = data.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;
      return {'lat': lat, 'lon': lon};
    } catch (e) {
      return null;
    }
  }
}
