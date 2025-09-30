import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/staff.dart';
import '../services/postgresql_service.dart';

// Staff State
class StaffState {
  final List<Staff> staffList;
  final bool isLoading;
  final String? error;
  final Staff? selectedStaff;

  const StaffState({
    this.staffList = const [],
    this.isLoading = false,
    this.error,
    this.selectedStaff,
  });

  StaffState copyWith({
    List<Staff>? staffList,
    bool? isLoading,
    String? error,
    Staff? selectedStaff,
  }) {
    return StaffState(
      staffList: staffList ?? this.staffList,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStaff: selectedStaff ?? this.selectedStaff,
    );
  }
}

// Staff Notifier
class StaffNotifier extends StateNotifier<StaffState> {
  StaffNotifier() : super(const StaffState());

  Future<void> loadStaffBySchool(String schoolId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final staffList = await PostgreSQLService.getStaffBySchool(schoolId);
      state = state.copyWith(
        staffList: staffList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createStaff(Staff staff) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Check if the schoolId looks like a UUID or a unique_id
      Staff staffToCreate = staff;
      
      if (!_isValidUUID(staff.schoolId)) {
        // This is likely a unique_id, we need to convert it to UUID
        print('🔍 Staff creation: schoolId "${staff.schoolId}" is not a UUID, treating as unique_id');
        staffToCreate = await _convertStaffSchoolIdToUUID(staff);
      }
      
      final newStaff = await PostgreSQLService.createStaff(staffToCreate);
      final updatedStaff = [...state.staffList, newStaff];
      state = state.copyWith(
        staffList: updatedStaff,
        isLoading: false,
      );
    } catch (e) {
      print('❌ Staff creation failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
  
  /// Check if a string is a valid UUID format
  bool _isValidUUID(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(id);
  }
  
  /// Convert staff with unique_id to proper UUID
  Future<Staff> _convertStaffSchoolIdToUUID(Staff staff) async {
    try {
      // Import the helper dynamically to avoid circular imports
      final schoolUUID = await _getSchoolUUIDFromUniqueId(staff.schoolId);
      if (schoolUUID == null) {
        throw Exception('School not found with unique_id: ${staff.schoolId}');
      }
      
      print('✅ Converted school unique_id "${staff.schoolId}" to UUID: $schoolUUID');
      return staff.copyWith(schoolId: schoolUUID);
    } catch (e) {
      print('❌ Failed to convert school ID: $e');
      rethrow;
    }
  }
  
  /// Helper function to get school UUID from unique_id
  Future<String?> _getSchoolUUIDFromUniqueId(String uniqueId) async {
    try {
      final schools = await PostgreSQLService.getSchools();
      final schoolList = schools.where((s) => s.uniqueId == uniqueId).toList();
      if (schoolList.isNotEmpty) {
        return schoolList.first.id;
      }
      return null;
    } catch (e) {
      print('❌ Error getting school UUID: $e');
      return null;
    }
  }

  Future<void> updateStaff(Staff staff) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedStaff = await PostgreSQLService.updateStaff(staff);
      final updatedStaffList = state.staffList.map((s) => 
        s.id == updatedStaff.id ? updatedStaff : s
      ).toList();
      
      state = state.copyWith(
        staffList: updatedStaffList,
        isLoading: false,
        selectedStaff: state.selectedStaff?.id == updatedStaff.id 
            ? updatedStaff 
            : state.selectedStaff,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> deleteStaff(String staffId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await PostgreSQLService.deleteStaff(staffId);
      
      // Refresh the staff list from database to ensure consistency
      await loadAllStaff();
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> loadAllStaff() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final staffList = await PostgreSQLService.getAllStaff();
      state = state.copyWith(
        staffList: staffList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<String> generateNextStaffId(String schoolId) async {
    return await PostgreSQLService.generateNextStaffId(schoolId);
  }

  void selectStaff(Staff staff) {
    state = state.copyWith(selectedStaff: staff);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final staffProvider = StateNotifierProvider<StaffNotifier, StaffState>((ref) {
  return StaffNotifier();
});

// School-specific staff provider family
final schoolStaffProvider = StateNotifierProvider.family<StaffNotifier, StaffState, String>((ref, schoolId) {
  return StaffNotifier()..loadStaffBySchool(schoolId);
});

// Computed providers
final selectedStaffProvider = Provider<Staff?>((ref) {
  return ref.watch(staffProvider).selectedStaff;
});

final staffByRoleProvider = Provider.family<List<Staff>, String>((ref, role) {
  final staffList = ref.watch(staffProvider).staffList;
  return staffList.where((staff) => staff.role == role).toList();
});