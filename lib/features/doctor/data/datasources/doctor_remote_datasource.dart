
import 'package:dio/dio.dart';
import '../models/doctor_model.dart';

class DoctorRemoteDataSource {
  final Dio _dio;

  DoctorRemoteDataSource(this._dio);

  Future<List<DoctorModel>> getAllDoctors() async {
    final response = await _dio.get('/doctors');
    final data = response.data;

    // The API may return a list directly or wrap it in an object.
    final List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic> && data.containsKey('data')) {
      items = data['data'] as List<dynamic>;
    } else {
      items = [];
    }

    return items
        .map((json) => DoctorModel.fromApiJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<DoctorModel?> getDoctorByUserId(String userId) async {
    try {
      final response = await _dio.get('/doctors/$userId');
      if (response.data == null) return null;
      return DoctorModel.fromApiJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> updateDoctorAvailability(String doctorId, bool isAvailable) async {
    await _dio.patch(
      '/doctors/$doctorId',
      data: {'is_available': isAvailable},
    );
  }
}
