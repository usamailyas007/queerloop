// Admin Users service — every /admin/users* call.
// Mirrors the app-side feature services (see features/profile_setup/profile_setup_service.dart).

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
import 'models/admin_user_account.dart';

class AdminUsersService {
  const AdminUsersService(this._client);

  final ApiClient _client;

  /// GET /admin/users — one page of accounts. `page` is 1-based.
  Future<AdminUsersPage> fetchUsers({
    required int page,
    required int limit,
    String? search,
    AdminAccountStatus? status,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null) 'status': status.query,
    };

    debugPrint('🚀 [AdminUsersService] GET ${ApiEndpoints.adminUsers} $query');
    final dynamic data = await _client.get(
      ApiEndpoints.adminUsers,
      query: query,
      useCache: false,
    );
    return AdminUsersPage.fromJson(data as Map<String, dynamic>);
  }

  /// GET /users/:id — the public profile projection (bio / pronouns /
  /// interests). Returns [UserProfileExtra.private] when the account hides its
  /// profile (403), or null on any other failure.
  Future<UserProfileExtra?> fetchProfile(String userId) async {
    try {
      debugPrint('🚀 [AdminUsersService] GET ${ApiEndpoints.user(userId)}');
      final dynamic data =
          await _client.get(ApiEndpoints.user(userId), useCache: false);
      return UserProfileExtra.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        return UserProfileExtra.hidden;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /admin/users/stats — aggregate counts for the header.
  Future<AdminUsersStats> fetchStats() async {
    debugPrint('🚀 [AdminUsersService] GET ${ApiEndpoints.adminUsersStats}');
    final dynamic data = await _client.get(
      ApiEndpoints.adminUsersStats,
      useCache: false,
    );
    return AdminUsersStats.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /admin/users/:id/status — suspend (with days) or reactivate.
  Future<void> updateStatus({
    required String userId,
    required AdminAccountStatus status,
    int? suspendDays,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'status': status.query,
      if (status == AdminAccountStatus.suspended && suspendDays != null)
        'suspendDays': suspendDays,
    };

    debugPrint('🚀 [AdminUsersService] PATCH ${ApiEndpoints.adminUserStatus(userId)} $body');
    await _client.patch(ApiEndpoints.adminUserStatus(userId), body: body);
  }

  /// DELETE /admin/users/:id — hard-delete an account.
  Future<void> deleteUser(String userId) async {
    debugPrint('🚀 [AdminUsersService] DELETE ${ApiEndpoints.adminUser(userId)}');
    await _client.delete(ApiEndpoints.adminUser(userId));
  }
}
