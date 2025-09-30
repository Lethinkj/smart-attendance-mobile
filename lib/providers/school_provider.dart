import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/school.dart';
import '../services/postgresql_service.dart';

// School State
class SchoolState {
  final List<School> schools;
  final bool isLoading;
  final String? error;
  final School? selectedSchool;

  const SchoolState({
    this.schools = const [],
    this.isLoading = false,
    this.error,
    this.selectedSchool,
  });

  SchoolState copyWith({
    List<School>? schools,
    bool? isLoading,
    String? error,
    School? selectedSchool,
  }) {
    return SchoolState(
      schools: schools ?? this.schools,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedSchool: selectedSchool ?? this.selectedSchool,
    );
  }
}

// School Notifier
class SchoolNotifier extends StateNotifier<SchoolState> {
  SchoolNotifier() : super(const SchoolState()) {
    loadSchools();
  }

  Future<void> loadSchools() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final schools = await PostgreSQLService.getSchools();
      state = state.copyWith(
        schools: schools,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createSchool(School school) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final newSchool = await PostgreSQLService.createSchool(school);
      final updatedSchools = [...state.schools, newSchool];
      state = state.copyWith(
        schools: updatedSchools,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
  
  Future<List<Map<String, String>>> createSchoolWithStaff(School school, String schoolType) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Create the school first
      final newSchool = await PostgreSQLService.createSchool(school);
      final updatedSchools = [...state.schools, newSchool];
      state = state.copyWith(
        schools: updatedSchools,
        isLoading: false,
      );
      
      // Generate staff accounts based on school type
      final staffList = await PostgreSQLService.generateStaffForSchool(newSchool, schoolType);
      final staffCredentials = staffList.map((staff) => {
        'Class': staff.assignedClasses.isNotEmpty ? 'Class ${staff.assignedClasses.first}' : 'No Class',
        'Staff Name': staff.name,
        'Username': staff.staffId.toLowerCase(),
        'Password': staff.password,
        'Staff ID': staff.staffId,
        'Email': staff.email,
        'Phone': staff.phone,
      }).toList();
      
      return staffCredentials;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
  


  Future<void> updateSchool(School school) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedSchool = await PostgreSQLService.updateSchool(school);
      final updatedSchools = state.schools.map((s) => 
        s.id == updatedSchool.id ? updatedSchool : s
      ).toList();
      
      state = state.copyWith(
        schools: updatedSchools,
        isLoading: false,
        selectedSchool: state.selectedSchool?.id == updatedSchool.id 
            ? updatedSchool 
            : state.selectedSchool,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> deleteSchool(String schoolId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('🔄 Provider: Deleting school with ID: $schoolId');
      await PostgreSQLService.deleteSchool(schoolId);
      
      final updatedSchools = state.schools.where((s) => s.id != schoolId).toList();
      print('📋 Provider: Schools remaining after deletion: ${updatedSchools.length}');
      
      state = state.copyWith(
        schools: updatedSchools,
        isLoading: false,
        selectedSchool: state.selectedSchool?.id == schoolId 
            ? null 
            : state.selectedSchool,
        error: null, // Clear any previous errors
      );
      
      print('✅ Provider: School deletion completed successfully');
    } catch (e) {
      print('❌ Provider: School deletion failed: $e');
      
      // Don't corrupt the state on error - keep existing schools
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete school: ${e.toString()}',
      );
      rethrow;
    }
  }

  void selectSchool(School school) {
    state = state.copyWith(selectedSchool: school);
  }

  Future<bool> isSchoolIdUnique(String uniqueId) async {
    return await PostgreSQLService.isSchoolIdUnique(uniqueId);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final schoolProvider = StateNotifierProvider<SchoolNotifier, SchoolState>((ref) {
  return SchoolNotifier();
});

// Computed providers
final selectedSchoolProvider = Provider<School?>((ref) {
  return ref.watch(schoolProvider).selectedSchool;
});

final schoolStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, schoolId) async {
  return await PostgreSQLService.getSchoolStats(schoolId);
});