// Admin Users service — GET /admin/users with page-based pagination.
// Mirrors the app-side feature services (see features/profile_setup/profile_setup_service.dart).

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import 'models/admin_user_account.dart';

class AdminUsersService {
  const AdminUsersService(this._client);

  final ApiClient _client;

  /// One page of accounts. `page` is 1-based.
  Future<AdminUsersPage> fetchUsers({
    required int page,
    int limit = 20,
    String? search,
    AdminAccountStatus? status,
  }) async {
    if (AppConfig.useMockApi) {
      return const AdminUsersPage(items: <AdminUserAccount>[], total: 0, page: 1, limit: 20);
    }

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
    final AdminUsersPage result =
        AdminUsersPage.fromJson(data as Map<String, dynamic>);
    debugPrint(
      '📥 [AdminUsersService] page ${result.page}/${(result.total / (result.limit == 0 ? 1 : result.limit)).ceil()} '
      '(${result.items.length} of ${result.total})',
    );
    return result;
  }
}
