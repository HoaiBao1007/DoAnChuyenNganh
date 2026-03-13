 HyperBuy – E-commerce Mobile Application
HyperBuy là ứng dụng thương mại điện tử trên nền tảng di động được phát triển bằng Flutter.
Ứng dụng cho phép người dùng duyệt sản phẩm, quản lý giỏ hàng, đặt hàng, đánh giá sản phẩm, nhận thông báo và sử dụng voucher giảm giá.
Dự án được xây dựng như một đồ án chuyên ngành, mô phỏng đầy đủ các chức năng của một hệ thống bán hàng hiện đại.
 Features
 Authentication
Đăng ký tài khoản
Đăng nhập / đăng xuất
Lấy thông tin hồ sơ người dùng
Cập nhật thông tin tài khoản
 Product Management
Xem danh sách sản phẩm
Xem sản phẩm theo danh mục
Xem chi tiết sản phẩm
Tìm kiếm sản phẩm
 Shopping Cart
Thêm sản phẩm vào giỏ hàng
Cập nhật số lượng sản phẩm
Xóa sản phẩm khỏi giỏ hàng
Hiển thị tổng giá trị giỏ hàng
 Order Management
Tạo đơn hàng
Xem danh sách đơn hàng
Xem chi tiết đơn hàng
Xem lịch sử đơn hàng
 Product Rating
Đánh giá sản phẩm
Xem danh sách đánh giá
Quản lý đánh giá của người dùng
- Voucher System
Hiển thị danh sách voucher
Áp dụng voucher khi thanh toán
- Notification System
Nhận thông báo từ hệ thống
Xem danh sách thông báo
- Technologies Used
Programming Language
Dart
Framework
Flutter
Networking
REST API
HTTP requests
Local Storage
SharedPreferences
Utilities
Intl (format date/time)

 Main Dependencies
| Package            | Description              |
| ------------------ | ------------------------ |
| http               | Gửi request đến REST API |
| shared_preferences | Lưu token đăng nhập      |
| intl               | Format ngày tháng        |

 Project Architecture
Dự án được tổ chức theo kiến trúc phân lớp để dễ bảo trì và mở rộng.
lib
│
├── api
│   └── api_client.dart
│
├── models
│   ├── product.dart
│   ├── cart_item.dart
│   ├── order_response.dart
│   ├── rating_response.dart
│   └── app_notification.dart
│
├── services
│   ├── auth_service.dart
│   ├── product_service.dart
│   ├── cart_service.dart
│   ├── order_service.dart
│   ├── rating_service.dart
│   ├── notification_service.dart
│   └── voucher_service.dart
│
├── screens
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── product_detail_screen.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── order_screen.dart
│   ├── rating_screen.dart
│   ├── notification_screen.dart
│   └── account_screen.dart
│
├── widgets
│
├── utils
│
├── state
│
└── main.dart
⚙️ Installation & Setup
1️ Clone repository
git clone https://github.com/HoaiBao1007/DoAnChuyenNganh.git
2️ Di chuyển vào thư mục dự án
cd DoAnChuyenNganh
3️ Cài đặt dependencies
flutter pub get
4️ Chạy ứng dụng
flutter run
- API Configuration
Các API endpoint hiện được cấu hình trong:
lib/api/api_client.dart
Ví dụ:
http://192.168.x.x:8080/api
Nếu chạy backend trên máy khác, hãy cập nhật địa chỉ API phù hợp.
- Main Screens
Screen	Description
Login	Đăng nhập
Register	Đăng ký
Home	Trang chủ
Category	Danh mục sản phẩm
Product Detail	Chi tiết sản phẩm
Cart	Giỏ hàng
Checkout	Thanh toán
Orders	Lịch sử đơn hàng
Rating	Đánh giá sản phẩm
Notifications	Thông báo
Account	Hồ sơ người dùng
Voucher	Danh sách voucher
- Future Improvements
Thanh toán online (VNPay / Stripe)
Wishlist sản phẩm
Push Notification
Chat hỗ trợ khách hàng
Admin dashboard
 License
This project is developed for learning and academic purposes.
