// file: lib/models/category_node_model.dart

class CategoryNodeModel {
final int id;
final String name;
final List<CategoryNodeModel> children; // Danh sách các danh mục con

CategoryNodeModel({
required this.id,
required this.name,
required this.children,
});

// Factory constructor để parse dữ liệu từ JSON
factory CategoryNodeModel.fromJson(Map<String, dynamic> json) {

// Parse danh sách các 'children' một cách đệ quy
// Hàm này sẽ được gọi cho mỗi phần tử trong mảng 'children' của JSON
List<CategoryNodeModel> parsedChildren = [];
if (json['children'] != null && json['children'] is List) {
parsedChildren = (json['children'] as List)
    .map((childJson) => CategoryNodeModel.fromJson(childJson as Map<String, dynamic>))
    .toList();
}

return CategoryNodeModel(
id: json['id'] as int? ?? 0, // Lấy id, nếu null thì mặc định là 0
name: json['name'] as String? ?? 'Không có tên', // Lấy name, nếu null thì có giá trị mặc định
children: parsedChildren, // Gán danh sách con đã được parse
);
}
}
