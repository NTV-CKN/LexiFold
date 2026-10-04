///Khi các lớp khác kế thừa lớp này, nó cần thực hiện 2 việc:
/// + Triển khai lại hàm toJson
/// + Tạo factory fromJson để convert Json về đối tượng
///
/// Phía gọi logic lên server sẽ phải truyền logic factory fromJson đó
/// để khi có dữ liệu trả về, nơi thực thi sẽ gọi lại hàm đó để tạo kết quả.
/// T extends BaseClassDto
abstract class BaseClassDto {
  Map<String, dynamic> toJson();
}
