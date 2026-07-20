
import '../../../../core/services/supabase_service.dart';
import '../models/doctor_model.dart';

import '../../../auth/data/models/user_model.dart';

class DoctorRemoteDataSource {
  final _client = SupabaseService.client;

  Future<List<DoctorModel>> getAllDoctors() async {
    try {
      final response = await _client
          .from('doctors')
          .select('*, profiles(*)');
      final list = (response as List).map((json) => DoctorModel.fromJson(json)).toList();
      if (list.isEmpty) {
        return _getDummyDoctors();
      }
      return list;
    } catch (e) {
      return _getDummyDoctors();
    }
  }

  List<DoctorModel> _getDummyDoctors() {
    final now = DateTime.now();
    return [
      DoctorModel(
        id: 'doc-1',
        userId: 'user-doc-1',
        specialty: 'Psychiatrist',
        qualifications: 'MD, MMed (Psychiatry)',
        consultationFee: 5000.0,
        isAvailable: true,
        createdAt: now,
        updatedAt: now,
        userProfile: UserModel(
          id: 'user-doc-1',
          firstName: 'Angela',
          lastName: 'Wambui',
          phoneNumber: '+254711222333',
          avatarUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300',
          bio: 'Recovery is a path of restoration and dignity. Let\'s walk it together.',
          role: 'doctor',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      DoctorModel(
        id: 'doc-2',
        userId: 'user-doc-2',
        specialty: 'Clinical Psychologist',
        qualifications: 'PhD in Clinical Psychology',
        consultationFee: 4500.0,
        isAvailable: true,
        createdAt: now,
        updatedAt: now,
        userProfile: UserModel(
          id: 'user-doc-2',
          firstName: 'David',
          lastName: 'Omondi',
          phoneNumber: '+254722333444',
          avatarUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300',
          bio: 'Understanding your emotional wellness is the first step towards healing.',
          role: 'psychologist',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      DoctorModel(
        id: 'doc-3',
        userId: 'user-doc-3',
        specialty: 'Therapist & Counselor',
        qualifications: 'MA in Counseling Psychology',
        consultationFee: 3500.0,
        isAvailable: true,
        createdAt: now,
        updatedAt: now,
        userProfile: UserModel(
          id: 'user-doc-3',
          firstName: 'Sarah',
          lastName: 'Chen',
          phoneNumber: '+254733444555',
          avatarUrl: 'https://images.unsplash.com/photo-1594824813573-246434de83fb?auto=format&fit=crop&q=80&w=300',
          bio: 'Providing a safe space for growth, resilience, and positive change.',
          role: 'therapist',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      DoctorModel(
        id: 'doc-4',
        userId: 'user-doc-4',
        specialty: 'Addiction Specialist',
        qualifications: 'MMed, Specialist in Recovery Care',
        consultationFee: 6000.0,
        isAvailable: true,
        createdAt: now,
        updatedAt: now,
        userProfile: UserModel(
          id: 'user-doc-4',
          firstName: 'James',
          lastName: 'Musembi',
          phoneNumber: '+254744555666',
          avatarUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=300',
          bio: 'Empowering you to reclaim control and thrive in daily life.',
          role: 'doctor',
          createdAt: now,
          updatedAt: now,
        ),
      ),
    ];
  }

  Future<DoctorModel?> getDoctorByUserId(String userId) async {
    final response = await _client
        .from('doctors')
        .select('*, profiles(*)')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return DoctorModel.fromJson(response);
  }

  Future<void> updateDoctorAvailability(String doctorId, bool isAvailable) async {
    await _client
        .from('doctors')
        .update({'is_available': isAvailable})
        .eq('id', doctorId);
  }
}
