import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';

class SearchRemoteDatasource {
  final Dio dio;

  SearchRemoteDatasource(this.dio);

  Future<Map<String, dynamic>> search(String query, String type, int page, int limit) async {
    final response = await dio.get(
      ApiEndpoints.search,
      queryParameters: {
        'q': query,
        'type': type,
        'page': page,
        'limit': limit,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
