import 'package:flutter/foundation.dart';
import '../models/pagination_types.dart';
import '../models/user.dart'; // PaginationInfo

/// Mixin to handle common paginated list logic.
///
/// Classes using this mixin must implement [fetchPage], [createItemApi], [updateItemApi], [deleteItemApi].
mixin PaginatedDataMixin<T> on ChangeNotifier {
  List<T> _items = [];
  PaginationInfo? _paginationInfo;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _errorMessage;
  final Map<String, dynamic> _filters = {};

  List<T> get items => _items;
  PaginationInfo? get paginationInfo => _paginationInfo;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  Map<String, dynamic> get filters => _filters;

  /// Consider the provider loaded when it's not loading, has no error and has items.
  /// Subclasses can override if they need a different semantics.
  bool get isLoaded => !_isLoading && !hasError && _items.isNotEmpty;

  /// Override to fetch a page of items. [filters] may include additional query params.
  Future<PaginatedResponse<T>?> fetchPage(String accessToken,
      {int page = 1, int? limit, String? search, Map<String, String>? filters});

  Future<void> loadItems(String accessToken,
      {int page = 1,
      int? limit,
      String? search,
      Map<String, String>? filters}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _hasMoreData = true;
    notifyListeners();

    try {
      final response = await fetchPage(accessToken,
          page: page, limit: limit, search: search, filters: filters);
      if (response != null) {
        _items = response.items;
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
      } else {
        _errorMessage = 'Error al cargar datos';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage(String accessToken) async {
    if (_paginationInfo == null ||
        !_paginationInfo!.hasNext ||
        _isLoading ||
        _isLoadingMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _paginationInfo!.page + 1;
      final response = await fetchPage(accessToken,
          page: nextPage,
          limit: _paginationInfo!.limit,
          filters: _filters.isNotEmpty
              ? _filters.map((k, v) => MapEntry(k, v.toString()))
              : null);
      if (response != null) {
        _items.addAll(response.items);
        _paginationInfo = response.pagination;
        _hasMoreData = response.pagination.hasNext;
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createItem(String accessToken, dynamic data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final item = await createItemApi(accessToken, data);
      if (item != null) {
        _items.insert(0, item);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateItem(String accessToken, String id, dynamic data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await updateItemApi(accessToken, id, data);
      if (updated != null) {
        final index = _items.indexWhere((it) => _getItemId(it) == id);
        if (index != -1) _items[index] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItem(String accessToken, String id) async {
    try {
      final success = await deleteItemApi(accessToken, id);
      if (success) {
        _items.removeWhere((it) => _getItemId(it) == id);
        notifyListeners();
      }
      return success;
      // ignore: empty_catches
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Subclasses must implement how to call the API to create an item
  Future<T?> createItemApi(String accessToken, dynamic data);

  /// Subclasses must implement how to call the API to update an item
  Future<T?> updateItemApi(String accessToken, String id, dynamic data);

  /// Subclasses must implement how to call the API to delete an item
  Future<bool> deleteItemApi(String accessToken, String id);

  /// Extract an id from T. Subclasses can override for custom lookup.
  String _getItemId(dynamic item) => (item as dynamic).id as String;

  /// Utility: reset pagination
  void resetPagination() {
    _items = [];
    _paginationInfo = null;
    _hasMoreData = true;
    _isLoadingMore = false;
  }

  /// Utility to clear items
  void clearItems() {
    _items = [];
    _paginationInfo = null;
    notifyListeners();
  }

  /// Utility to set a custom error message
  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear the current error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set a filter value
  void setFilter(String key, dynamic value) {
    _filters[key] = value;
    notifyListeners();
  }

  /// Remove a filter
  void removeFilter(String key) {
    _filters.remove(key);
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _filters.clear();
    notifyListeners();
  }

  /// Utility: override internal pagination info (used by providers when
  /// an endpoint returns a custom pagination or when loading non-paginated
  /// content that should mark no more data).
  ///
  /// This setter respects `PaginationInfo.hasNext` to update `hasMoreData`.
  void setPaginationInfo(PaginationInfo? info) {
    _paginationInfo = info;
    _hasMoreData = info?.hasNext ?? false;
    notifyListeners();
  }

  /// Utility: manually set whether the provider has more data.
  /// Useful for endpoints that return all results (no pagination) and the
  /// provider must inform the UI there is no more data to load.
  void setHasMoreData(bool hasMore) {
    _hasMoreData = hasMore;
    notifyListeners();
  }

  /// Utility: manually set whether `isLoadingMore` is active. Useful when
  /// a provider is using a custom "load more" endpoint and needs to expose
  /// the loading-more flag to the UI.
  void setIsLoadingMore(bool value) {
    _isLoadingMore = value;
    notifyListeners();
  }
}
