# Hướng dẫn cài đặt và triển khai Savor POS

Tài liệu dựa trên mã nguồn trong repository ngày 26/10/2026. Chưa xác nhận triển khai đầu cuối với MySQL và thiết bị Android. Không thực hiện import, chép đè backend hoặc thay đổi dịch vụ trong quá trình viết tài liệu.

## 1. Mô hình triển khai

Ứng dụng Flutter -> HTTP API PHP -> MySQL.

- Mã Flutter: `D:\New folder\lib`.
- Backend đầy đủ: `D:\New folder\backend\pos_api`.
- Thư mục triển khai Laragon dự kiến: `C:\laragon\www\pos_api`.
- URL API: `http://localhost/pos_api/v1` trên máy chủ.
- File schema tương ứng API: `backend/pos_api/query.sql`.
- Không dùng `docs/schema.sql` hoặc `docs/seed.sql`: đây là mô hình cũ.
- Không dùng `backend/index.php`: file này tham chiếu các đường dẫn không khớp cấu trúc hiện tại. Entry point đúng là `backend/pos_api/index.php`.

## 2. Sao lưu trước khi khôi phục

Máy đã có hai thư mục `C:\laragon\www\pos_api` và `C:\laragon\www\pos_api_v1`. Chưa xác định chúng có dữ liệu hoặc thay đổi mới hơn repository hay không.

1. Sao chép nguyên thư mục backend đang dùng sang thư mục backup riêng, bao gồm `uploads` và `.htaccess`.
2. Mở công cụ quản lý MySQL của Laragon, export database hiện có thành file SQL gồm cấu trúc và dữ liệu.
3. Giữ bản sao `config.php` để biết database, user, port cũ. Không đưa mật khẩu vào Git.
4. Chỉ import schema bên dưới cho database mới, rỗng. Nếu đã có dữ liệu, cần đối chiếu schema và migration; không xóa database để giải quyết lỗi thiếu bảng.

## 3. Kiểm tra công cụ

Trong PowerShell:

```powershell
Set-Location 'D:\New folder'
flutter --version
flutter doctor -v
php -v
php -m
```

Máy hiện có Flutter tại `C:\flutter` và PHP 8.4.13 của Laragon. PHP CLI đã có `PDO` và `pdo_mysql`; PHP dùng bởi Apache cũng cần bật extension này.

Backend dùng các hàm PHP 8; chọn PHP 8.x. Schema ghi mục tiêu MySQL 8+. Với Android, cần Android Studio, Android SDK và emulator hoặc điện thoại bật USB debugging.

Nếu `flutter doctor` báo thiếu Android license:

```powershell
flutter doctor --android-licenses
```

Chỉ cần xử lý các mục doctor liên quan nền tảng đang chạy. Repository có Android và Web, chưa có cấu trúc Windows desktop hoặc iOS.

## 4. Khởi động backend bằng Laragon

1. Mở Laragon, chọn Apache và MySQL rồi khởi động hai dịch vụ.
2. Sau khi sao lưu, đồng bộ nội dung `D:\New folder\backend\pos_api` vào `C:\laragon\www\pos_api` nếu chọn dùng bản repository.
3. Thư mục đích phải chứa trực tiếp `index.php`, `config.php`, `.htaccess`, `controllers`, `repos`, `services`, `lib`, `uploads`. Tránh lồng thành `pos_api\pos_api`.
4. Apache phải nạp `mod_rewrite` và cho phép các chỉ thị trong `.htaccess` tại thư mục này. Nếu sửa cấu hình Apache, restart Apache.
5. Giữ URL dưới `/pos_api/`: `.htaccess` và hàm tạo URL ảnh hiện đều gắn với đường dẫn đó.

Trong bản `config.php` được triển khai, điều chỉnh theo MySQL thực tế:

```php
define('DB_DSN', 'mysql:host=localhost;port=3306;dbname=pos;charset=utf8mb4');
define('DB_USER', 'TEN_USER_MYSQL');
define('DB_PASS', 'MAT_KHAU_MYSQL');
```

User database này khác với tài khoản đăng nhập POS. Dự án đang mặc định root/mật khẩu trống; dùng thông tin thực tế của máy, và dùng user riêng khi triển khai vận hành.

Tài khoản chạy PHP cần quyền ghi trong `uploads`. Mã sẽ tạo các thư mục ảnh con khi upload.

## 5. Tạo database mới và tài khoản đầu tiên

Chỉ thực hiện nếu khởi tạo mới. `query.sql` tạo và chọn database `pos`, nhưng các câu `CREATE TABLE` không được thiết kế để chạy lặp trên database đã có bảng.

1. Mở công cụ quản lý MySQL từ Laragon và kết nối MySQL.
2. Mở file `D:\New folder\backend\pos_api\query.sql` và thực thi trên server phát triển mới/rỗng.
3. Kiểm tra có các bảng `users`, `areas`, `dining_tables`, `items`, `orders`, `payment_methods`, `receipts`.
4. File chỉ tạo cấu trúc, không tạo tài khoản hoặc dữ liệu mẫu.
5. Trên database mới, thay các mật khẩu mẫu bên dưới bằng mật khẩu riêng rồi thực thi:

```sql
USE pos;

INSERT INTO users (name, username, password_plain, role, is_active)
VALUES
  ('Quản trị', 'admin', 'THAY_MAT_KHAU_ADMIN', 'admin', 1),
  ('Thu ngân', 'cashier', 'THAY_MAT_KHAU_THU_NGAN', 'cashier', 1),
  ('Bếp', 'kitchen', 'THAY_MAT_KHAU_BEP', 'kitchen', 1);

INSERT INTO payment_methods (code, name, enabled)
VALUES ('cash', 'Tiền mặt', 1);
```

Phương thức `cash` cần tồn tại để checkout mặc định thành công. Lưu ý mã hiện tại yêu cầu `password_plain`; chuyển sang hash cần sửa đồng bộ backend, không tự thay nội dung cột bằng hash.

## 6. Kiểm tra API trước khi chạy Flutter

Mở trên máy chủ: `http://localhost/pos_api/ping.php`.

Kỳ vọng JSON có `ok: true`. Ping chỉ chứng minh PHP phản hồi, chưa kiểm tra MySQL.

Kiểm tra đăng nhập bằng PowerShell, nhập mật khẩu riêng tại máy:

```powershell
$credential = Get-Credential -UserName admin -Message 'Tai khoan POS vua tao'
$body = @{
  username = $credential.UserName
  password = $credential.GetNetworkCredential().Password
} | ConvertTo-Json
$session = Invoke-RestMethod -Method Post `
  -Uri 'http://localhost/pos_api/v1/auth/login' `
  -ContentType 'application/json' -Body $body
$session.ok

$headers = @{ Authorization = "Bearer $($session.data.token)" }
Invoke-RestMethod -Uri 'http://localhost/pos_api/v1/categories' -Headers $headers
```

Login thành công và categories trả dữ liệu hoặc danh sách rỗng xác nhận được luồng PHP -> MySQL -> xác thực -> API danh mục. Không chia sẻ token hoặc toàn bộ biến session.

Nếu route đẹp `/v1/...` trả 404, thử `/pos_api/index.php/v1/auth/login` với cùng POST để phân biệt lỗi rewrite; PATH_INFO cũng cần được Apache/PHP cho phép. Sửa rewrite để quay về URL chuẩn, tránh đổi base sang `index.php` vì URL ảnh hiện được ghép từ base.

## 7. Chọn URL API theo nơi chạy ứng dụng

Sửa `D:\New folder\lib\config.dart`:

```dart
const String apiBase = 'http://10.0.2.2/pos_api';
const String apiVersionPath = '/v1';
```

| Nơi chạy Flutter | Giá trị apiBase |
|---|---|
| Android Studio emulator tiêu chuẩn | `http://10.0.2.2/pos_api` |
| Chrome trên chính máy chạy Laragon | `http://localhost/pos_api` |
| Android thật hoặc trình duyệt trên máy khác cùng LAN | `http://IP_MAY_CHU/pos_api` |

Ví dụ IP máy chủ là `192.168.1.20` thì dùng `http://192.168.1.20/pos_api`. Đây là ví dụ, cần thay IP thực tế. Nếu Apache chạy cổng khác 80, thêm cổng, ví dụ `:8080`, vào URL.

Không thêm `/v1` vào apiBase vì apiVersionPath đã có. Mỗi lần đổi môi trường cần khởi động lại hoặc build lại ứng dụng; dự án chưa hỗ trợ `--dart-define` cho cấu hình này.

## 8. Chạy Flutter Android

```powershell
Set-Location 'D:\New folder'
flutter pub get
flutter devices
flutter run -d ID_THIET_BI
```

Thay `ID_THIET_BI` bằng ID từ `flutter devices`. Đăng nhập bằng tài khoản đã tạo trong bảng users.

Nếu HTTP nội bộ bị Android chặn, cho phép HTTP chỉ trong cấu hình debug tại `android/app/src/debug/AndroidManifest.xml`, bên trong thẻ manifest và cùng cấp uses-permission:

```xml
<application android:usesCleartextTraffic="true" />
```

Đây là cấu hình phát triển cho API HTTP. Khi đưa ra Internet, dùng HTTPS.

## 9. Chạy trên điện thoại Android thật

1. Máy chủ và điện thoại cùng mạng LAN/Wi-Fi, không bật cách ly thiết bị trên mạng khách.
2. Chạy `ipconfig` trên máy chủ, lấy IPv4 của card mạng đang dùng.
3. Trên điện thoại mở `http://IP_MAY_CHU/pos_api/ping.php` trước. Nếu chưa mở được, xử lý kết nối LAN trước khi sửa Flutter.
4. Apache cần lắng nghe trên giao diện LAN; cho phép đúng cổng Apache qua Windows Firewall trên mạng Private. Không cần mở cổng MySQL cho điện thoại.
5. Đổi apiBase sang IP đó, kết nối USB, bật USB debugging, cho phép máy tính truy cập, rồi dùng `flutter run`.
6. Khi dùng ổn định, đặt DHCP reservation/IP cố định cho máy chủ để URL không đổi.

## 10. Chạy Flutter Web để phát triển

Web cần điều chỉnh CORS vì Flutter gửi thêm `X-Auth-Token`. Trong bản `config.php` PHP đang được Apache phục vụ, cập nhật header hiện có thành:

```php
header('Access-Control-Allow-Headers: Authorization, Content-Type, X-Auth-Token');
```

Sau đó đặt apiBase thành localhost và chạy:

```powershell
flutter run -d chrome
```

Đây là chế độ phát triển. Khi triển khai web thật, giới hạn origin về tên miền frontend và dùng HTTPS cho cả frontend/backend; không giữ wildcard CORS như một cấu hình vận hành mặc định.

## 11. Tạo dữ liệu thử nghiệm và kiểm tra luồng

Đăng nhập admin để tạo danh mục, món, khu vực, bàn và topping nếu cần. Đăng nhập thu ngân để chọn bàn -> mở đơn -> chọn món -> gửi bếp. Dùng thiết bị hoặc trình duyệt khác đăng nhập bếp, cập nhật món. Thu ngân thanh toán, xem hóa đơn và thử in.

Hàng đợi bếp có chu kỳ tự tải lại 30 giây khi bật; có thể làm mới thủ công. Dùng dữ liệu thử, không coi báo cáo doanh thu hiện tại là số đối soát cuối cùng vì còn các lỗi đã nêu trong phân tích dự án.

## 12. Build APK và Web

Trước khi build APK release, thêm quyền mạng trong `android/app/src/main/AndroidManifest.xml`, là con trực tiếp của manifest:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Quyền này hiện chỉ có trong debug/profile. Nếu bản APK thử nội bộ vẫn dùng HTTP, cần cấu hình cho phép cleartext trong biến thể tương ứng; cấu hình chỉ đặt ở debug không áp dụng cho release. Bản triển khai thực tế nên chuyển API sang HTTPS.

```powershell
flutter build apk --release
```

APK dự kiến: `D:\New folder\build\app\outputs\flutter-apk\app-release.apk`.

Project hiện ký release bằng debug key. Cần thiết lập applicationId và khóa ký riêng trước khi phát hành chính thức, đồng thời bảo quản khóa để cập nhật được các phiên bản sau.

Build Web sau khi cấu hình apiBase đúng cho người truy cập:

```powershell
flutter build web --release
```

Đầu ra: `D:\New folder\build\web`. Có thể phục vụ nội dung thư mục này ở gốc một website Apache riêng. Nếu đặt Flutter Web trong thư mục con, cần cấu hình base href phù hợp. PHP và uploads vẫn được triển khai riêng tại `/pos_api`.

## 13. Lỗi thường gặp

| Hiện tượng | Kiểm tra |
|---|---|
| Ping lỗi/kết nối bị từ chối | Apache, cổng, IP, Firewall |
| Ping được nhưng login lỗi DB | MySQL đã chạy, DSN, tên database, user/password, pdo_mysql của Apache |
| `/v1/...` trả 404 | Đúng thư mục backend, mod_rewrite, .htaccess và AllowOverride |
| Thiếu bảng/cột | Đã import đúng query.sql chưa; docs/schema.sql là schema cũ |
| Không đăng nhập được | Bảng users có tài khoản, is_active=1, password_plain đúng |
| Thanh toán báo Invalid payment method: cash | Tạo payment_methods với code cash và enabled=1 |
| Chrome báo CORS | Cho phép X-Auth-Token, đúng origin và phản hồi OPTIONS |
| Emulator chạy, máy thật không chạy | Đổi 10.0.2.2 thành IP LAN của máy chủ |
| Debug chạy, APK release không có mạng | INTERNET trong manifest main, HTTPS/cleartext policy, URL được build vào app |
| Ảnh lỗi | uploads còn đủ file, PHP có quyền ghi, URL ảnh giữ /pos_api |
| Nút kiểm tra kết nối trong app báo lỗi | Nút đang gọi /v1/health không có trong router; dùng ping.php và login để kiểm tra |
| dart analyze báo app.dart không tồn tại | Test cũ import sai; chưa có căn cứ kết luận ứng dụng chính không build chỉ từ lỗi này |

## 14. Điều kiện trước khi đưa lên Internet

Mã hiện có token dễ giả mạo và mật khẩu dạng plain text. Chưa nên mở API công khai. Cần sửa xác thực/phân quyền, kiểm tra thanh toán và các vấn đề dữ liệu đã ghi nhận; sau đó mới triển khai HTTPS, user MySQL riêng, backup tự động cả database và uploads, khóa ký release và giới hạn CORS.

Tài liệu chính thức tham khảo:

- Flutter Android setup: https://docs.flutter.dev/platform-integration/android/setup
- Flutter networking / INTERNET: https://docs.flutter.dev/data-and-backend/networking
- Apache AllowOverride: https://httpd.apache.org/docs/2.4/mod/core.html#allowoverride
