# 🎵 Vibe Music Player

![Flutter](https://img.shields.io/badge/Flutter-3.27.4-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.6.0-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-API_21+-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.style=for-the-badge)

Một ứng dụng nghe nhạc **Offline** hiện đại, mượt mà và siêu nhẹ dành cho hệ điều hành **Android**, được phát triển bằng **Flutter** & **Dart**.

---

## 📲 Tải Về Trực Tiếp (Latest Release APK)

Bạn có thể tải ngay file cài đặt APK bản mới nhất đã được build tự động qua GitHub Actions:

👉 **[Tải VibeMusicApp.apk (Bản Mới Nhất)](https://raw.githubusercontent.com/pmduc97/node24_repo/my_music_app/releases/VibeMusicApp.apk)**

---

## ✨ Tính Năng Nổi Bật

- 🎵 **Phát Nhạc Offline Đa Định Dạng**: Hỗ trợ MP3, M4A, WAV, FLAC, AAC, OGG, OPUS, WMA, AMR.
- 📁 **Chọn File & Thư Mục Thông Minh**: Lọc duy nhất các định dạng file âm thanh (`audio/*`), tự động loại bỏ các tập tin không phải nhạc.
- 🌙 **Phát Nhạc Chạy Nền & Màn Hình Khóa (Background Playback)**: Sử dụng `audio_service` hiển thị bảng điều khiển phát nhạc chuyên nghiệp trên thanh thông báo và màn hình khóa.
- ⚡ **Hiệu Năng Cao & Không Đơ UI (Zero-Freeze)**: Quét thư mục bất đồng bộ dạng Stream (`dir.list`), tra cứu O(1) bằng `Set`, phản hồi cảm ứng 0ms.
- 🔄 **Tự Động Cập Nhật Trực Tiếp Trong App (In-App Auto Update)**: Tự động kiểm tra phiên bản mới từ GitHub, hiển thị Release Notes và tải/cài đặt APK ngay trong app.
- ⏰ **Hẹn Giờ Tắt Nhạc (Sleep Timer)**: Cài sẵn các mốc 15, 30, 45, 60 phút hoặc tùy chỉnh số phút theo ý muốn.
- 🔀 **Chế Độ Phát Linh Hoạt**: Hỗ trợ Trộn bài (Shuffle), Lặp 1 bài (Loop One), Lặp danh sách (Loop All).
- 🎛️ **Kéo Thả Sắp Xếp Danh Sách**: Dễ dàng di chuyển vị trí các bài hát trong danh sách phát bằng thao tác kéo thả.
- 📦 **Tối Ưu Dung Lượng & Bảo Mật**: Áp dụng R8 Shrinking, nén tài nguyên, dung lượng APK siêu nhẹ chỉ **~23MB**.

---

## 🛠️ Công Nghệ Sử Dụng (Tech Stack)

- **Framework**: Flutter `3.27.4` (Stable Channel)
- **Language**: Dart `3.6.0` (Strict Type Safety)
- **State Management**: `provider` (ChangeNotifier)
- **Audio Core**: `just_audio` + `audio_service` (Foreground Media Playback Service)
- **File Management**: `file_picker` + `permission_handler`
- **In-App Installer**: `open_filex` + `http` + `path_provider`
- **UI Design**: Modern Dark Theme (Material Design 3, Google Fonts Inter, Gradients `#E94057` → `#F27121`)

---

## ⚙️ Hướng Dẫn Build Dự Án (Local Development)

### Đòi hỏi môi trường:
- Flutter SDK `3.27.4` trở lên
- Java JDK `21`
- Android SDK (compileSdk `35`, minSdk `21`)

### Các bước thực hiện:

1. **Clone repository & chuyển branch**:
   ```bash
   git clone https://github.com/pmduc97/node24_repo.git
   cd node24_repo
   git checkout my_music_app
   ```

2. **Cài đặt dependencies**:
   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng thử nghiệm**:
   ```bash
   flutter run
   ```

4. **Build bản Release APK**:
   ```bash
   flutter build apk --release
   ```
   *File APK đầu ra sẽ nằm tại: `build/app/outputs/flutter-apk/app-release.apk`*

---

## 🚀 Quy Trình CI/CD Tự Động (GitHub Actions)

Dự án được tích hợp workflow CI/CD tự động tại `.github/workflows/build_apk.yml`:
- Khi có bất kỳ commit nào được push lên branch `my_music_app`:
  1. GitHub Actions sẽ tự động dựng môi trường Java 21 & Flutter SDK.
  2. Thực hiện `flutter build apk --release`.
  3. Đóng gói và lưu trữ Artifacts.
  4. Tự động commit & push file `releases/VibeMusicApp.apk` và `releases/version.json` về lại branch.

---

## 📜 Giấy Phép (License)

Dự án được phát hành theo giấy phép [MIT License](LICENSE).
