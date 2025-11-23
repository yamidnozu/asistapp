import 'user.dart'; // PaginationInfo

/// Generic paginated response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationInfo pagination;

  PaginatedResponse({required this.items, required this.pagination});
}