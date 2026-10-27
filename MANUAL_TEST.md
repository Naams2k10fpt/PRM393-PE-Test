# Chạy và kiểm tra thủ công BookShelf

**QE190117 — Phạm Huỳnh Sum**. Source: `D:\PRM393\bookshelf`. Firebase project: `prm393-pe-71dac`. Android package: `com.prm393.bookshelf`.

## Chạy app

Cách nhanh: tải APK được bàn giao hoặc từ GitHub Releases và cài vào Android.

Chạy từ source bằng PowerShell:

```powershell
cd D:\PRM393\bookshelf
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Thay `emulator-5554` bằng ID Android từ `flutter devices`. Nếu chưa có thiết bị, mở Android Studio → Device Manager và chạy emulator, hoặc kết nối điện thoại có USB debugging. Project hiện cấu hình Android; chọn thiết bị Android.

Nếu thiếu SDK/license, xem `flutter doctor`, chạy `flutter doctor --android-licenses` và xử lý các mục được báo. Firebase client config thật đã có trong source. Không thêm admin/service-account key.

Tài khoản chính: `grader.qe190117@example.com`. Mật khẩu nằm trong `D:\PRM393\submission-private\test-config.json`, khóa `TEST_PASSWORD`. Không đưa file này lên GitHub.

Năm sách mẫu ban đầu cho kết quả `Books: 5`, `Favorites: 3`, breakdown `To Read: 2`, `Reading: 2`, `Finished: 1`.

## Kiểm tra theo thứ tự

| Bước | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| 1 | Mở app khi logout | Home có BookShelf, Login, Register; cuộn thấy ít nhất ba feature card |
| 2 | Login submit rỗng rồi nhập email sai | Email is required; Password is required; Please enter a valid email address |
| 3 | Login sai password | Lỗi Firebase nằm dưới submit, không chuyển màn hình |
| 4 | Login đúng tài khoản chính | List có email, Logout và các sách mẫu |
| 5 | Bấm Back trên List; tắt/mở app | Không về Login/Register; phiên đăng nhập được giữ |
| 6 | Logout, vào Register, submit rỗng | Lỗi email, password, confirm nằm dưới trường; trước submit không có lỗi |
| 7 | Register password ngắn, confirm khác | Password must be at least 6 characters; Passwords do not match; sửa đúng thì lỗi mất |
| 8 | Register bằng email mới | Registration successful; List của tài khoản mới có No books found |
| 9 | Logout, Register lại email đó | Lỗi Firebase dưới submit, không tạo thêm tài khoản |
| 10 | Login lại tài khoản chính | Chỉ thấy sách của tài khoản chính |
| 11 | Add a book → Add book khi trống | Lỗi title, author, genre, status; dropdown đầu là Choose genre và Choose status |
| 12 | Nhập title/author toàn khoảng trắng | Title is required / Author is required |
| 13 | Title 101, author 61, notes 301 ký tự | Thông báo giới hạn 100, 60, 300 đúng đề |
| 14 | Rating 2.5, 6, -1 hoặc chữ | Rating must be a whole number from 0 to 5; để trống, 0 và 5 hợp lệ |
| 15 | Thêm A test book / QE190117 hợp lệ | Book added; form reset; sách hiện đúng thứ tự alphabet và còn sau restart |
| 16 | Thêm trùng title/author với hoa/thường khác | Báo trùng, không thêm và không ghi đè sách cũ |
| 17 | Mở Filters & search, thử từng control | Genre, status, Favorites only, search cập nhật ngay |
| 18 | Search `  fRaNk  ` và kết hợp các filter | Tìm title/author không phân biệt hoa/thường, bỏ khoảng trắng hai đầu; kết hợp bằng AND |
| 19 | Kiểm tra summary sau mỗi filter | Books/Favorites chỉ đếm kết quả hiện tại; breakdown giảm dần, hòa thì To Read → Reading → Finished |
| 20 | Đang Favorites only, bỏ star một sách | Sách biến mất và counts đổi ngay; favorite vẫn giữ sau restart |
| 21 | Clear; tìm từ không tồn tại | Clear reset cả bốn control; rỗng hiện No books found, Books: 0, Favorites: 0 |
| 22 | Mở sách, Edit dữ liệu sai rồi Save | Detail đủ sáu trường; lỗi giống Add |
| 23 | Sửa bản nháp rồi Cancel | Không lưu thay đổi |
| 24 | Đổi title/author thành cặp mới và Save | Detail/List cập nhật; đổi thành cặp đã có thì bị chặn và không mất sách |
| 25 | Xóa nội dung rating và Save | Trở về chưa đánh giá, không giữ số cũ |
| 26 | Star trên Detail rồi Back | List cập nhật ngay |
| 27 | Với A test book, Delete → Cancel | Sách vẫn còn |
| 28 | Delete → Delete; restart | Quay về List, sách đã mất và vẫn mất sau restart |

Trong lúc kiểm tra, lưu ảnh từ emulator/điện thoại thật. Đừng xóa năm sách mẫu trước khi chụp các ảnh cần có dữ liệu.

## Firebase và rules

Mở Firebase Console đúng project `prm393-pe-71dac`:

- Authentication → Users: có tài khoản chính và tài khoản mới đăng ký.
- Firestore → Data: collection cấp gốc `books`, mỗi `userId` khớp UID của chủ sách.
- Firestore → Rules: rules đã publish và khớp file `firestore.rules`.

Ghi bằng quyền quản trị trong Console không chứng minh rules có chặn client. Nếu muốn tự chạy bộ kiểm tra bảo mật cục bộ:

```powershell
cd D:\PRM393\bookshelf
npm.cmd --prefix tools ci
.\tools\node_modules\.bin\firebase.cmd emulators:exec --project demo-bookshelf --only firestore "npm.cmd --prefix tools test"
```

Cần Java 21+. Kết quả mong đợi: **53 test pass**, gồm truy cập chéo, dữ liệu sai, sách trùng và đổi tên bằng transaction. Bộ này dùng emulator, không thay dữ liệu Firebase thật.

## Ảnh cho báo cáo Word

Chèn ảnh kèm caption theo thứ tự đề:

1. Firebase console — Authentication: Users có tài khoản chính.
2. Firebase console — Firestore data: books có ít nhất ba document của tài khoản chính.
3. Firebase console — Security Rules: rules đã publish.
4. Register screen — validation.
5. Register screen — success: có Registration successful.
6. Login screen: form trống.
7. List screen — after login: email, Logout và ít nhất ba sách; thu gọn Filters và chụp thêm ảnh nếu cần.
8. Add Book form — validation.
9. Add Book form — success: Book added và sách mới.
10. Filters and search: chứng minh đủ bốn control.
11. Summary: Books, Favorites, breakdown với hơn một status.
12. Detail screen — view mode.
13. Detail screen — edit mode, validation.
14. Detail screen — after Save.
15. Favorite toggle: cặp ảnh trước/sau.
16. Delete: cặp ảnh trước/sau, thấy sách đã mất.
17. Empty state: No books found với tài khoản mới.
18. Home và ảnh bổ sung cho các tính năng đã xây dựng.

Ảnh phải từ buổi chạy app thật; không dùng mockup. Ảnh không caption hoặc không khớp tính năng sẽ không được tính.

## Bài nộp

Tạo Word thật tên `QE190117.docx`. Giữ nhãn như đề và điền password từ file riêng:

```text
Student Code: QE190117
Full Name: Phạm Huỳnh Sum
GitHub Repository URL: https://github.com/Naams2k10fpt/PRM393-PE-Test
APK Download Link: https://github.com/Naams2k10fpt/PRM393-PE-Test/releases/download/v1.0.0/app-release.apk
Firebase Project ID: prm393-pe-71dac
Test account email: grader.qe190117@example.com
Test account password: <TEST_PASSWORD trong file riêng>
```

File source bàn giao là `QE190117.zip`; mở ZIP phải thấy `pubspec.yaml` ngay gốc. Không thêm build/cache, .git hay admin key. Không đưa báo cáo có password lên repository public.

Mở GitHub và link APK khi chưa đăng nhập để kiểm tra tải công khai. Cài APK và login bằng đúng tài khoản ghi trong Word. Nộp cùng thư mục chứa **QE190117.docx** và **QE190117.zip**. Nếu sửa source sau khi nhận ZIP, tạo lại ZIP và cập nhật GitHub/APK để cùng phiên bản.
