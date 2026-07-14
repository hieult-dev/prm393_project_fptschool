# My FSchool Mobile

Flutter client cho ba vai trò của backend `prm393-be`:

- `STUDENT`: xem điểm, chi tiết điểm và lịch học của chính mình.
- `PARENT`: xem danh sách sinh viên đã liên kết, điểm và lịch của từng sinh viên.
- `TEACHER`: xem lịch dạy, chọn học kỳ/môn được phân công và tạo hoặc cập nhật điểm.

Ứng dụng điều hướng bằng mảng `roles` từ response đăng nhập. Điều này hỗ trợ đúng
tài khoản cũ có đồng thời `LECTURER` và `TEACHER`.

## Cấu hình backend

URL API được cấu hình bằng `API_BASE_URL`. Mặc định Android là URL Android
Emulator `http://10.0.2.2:8080/api`; web mặc định dùng
`http://localhost:8080/api`.

Chạy trên thiết bị thật cùng mạng LAN với máy backend (thay IP khi mạng đổi):

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.11:8080/api
```

Chạy trên Android Emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

Trước khi thử parent/teacher, backend cần chạy Flyway V18–V20 và admin phải:

- tạo/gán role `PARENT`, sau đó liên kết các student;
- tạo/gán role `TEACHER`, gán các subject và `teacher_id` cho lịch;
- enroll student vào subject của semester tương ứng.

Các URL HTTP/cleartext ở trên chỉ dành cho phát triển nội bộ. Bản production nên
dùng HTTPS để bảo vệ mật khẩu và JWT.

## Kiểm tra

```powershell
flutter analyze
flutter test
```

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
