import 'package:flutter_test/flutter_test.dart';
import 'package:asistapp/providers/paginated_data_provider.dart';
import 'package:asistapp/models/user.dart';

class DummyItem {
  final String id;
  final String name;

  DummyItem(this.id, this.name);
}

class FakePaginatedProvider extends PaginatedDataProvider<DummyItem> {

  @override
  Future<PaginatedResponse<DummyItem>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
  // Simulate page fetch
    // single page with 2 items, next page when page==1
    final items = [DummyItem('1', 'One'), DummyItem('2', 'Two')];
  final pagination = PaginationInfo(page: page, limit: limit ?? 10, total: 2, totalPages: 1, hasNext: page < 2, hasPrev: page > 1);
    return PaginatedResponse(items: items, pagination: pagination);
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return true;
  }

  @override
  Future<DummyItem?> createItemApi(String accessToken, data) async {
    return DummyItem('3', 'Three');
  }

  @override
  Future<DummyItem?> updateItemApi(String accessToken, String id, data) async {
    return DummyItem(id, 'Updated');
  }
}

void main() {
  test('PaginatedDataProvider load items and next page', () async {
    final provider = FakePaginatedProvider();
    await provider.loadItems('token');
    expect(provider.items.length, 2);
    expect(provider.paginationInfo?.page, 1);

  await provider.loadNextPage('token');
  // Our fake returns the same items for page 2, so they will be appended
  expect(provider.items.length, 4);

    // create item
    final result = await provider.createItem('token', {});
    expect(result, isTrue);
    expect(provider.items.first.id, '3');

    // update item
    final updateResult = await provider.updateItem('token', '1', {});
    expect(updateResult, isTrue);

    // delete item
    final deleteResult = await provider.deleteItem('token', '1');
    expect(deleteResult, isTrue);
  });
}
