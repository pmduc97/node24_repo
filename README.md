# Hướng Dẫn Cài Đặt & Kiểm Tra Mạng Cho Antigravity CLI (`agy`)

Tài liệu này hướng dẫn cách kiểm tra quyền truy cập mạng, kiểm tra whitelist firewall/proxy và cài đặt `agy` ngoại tuyến / di động (Portable) trên máy mới.

---

## 1. Cấu trúc thư mục gói cài đặt

```text
agy_zip/
├── bin/
│   └── agy.exe                   # File thực thi chính của Antigravity CLI (~184MB)
├── check_connection.ps1          # Script test kết nối TRỰC TIẾP (Không qua Proxy)
├── check_connection_proxy.ps1    # Script test kết nối CÓ PROXY
├── install.ps1                   # Script cài đặt tự động bằng PowerShell
├── install.bat                   # Script cài đặt tự động bằng Command Prompt (click đúp)
└── README.md                     # Tài liệu hướng dẫn này
```

---

## 2. Checklist Các Kết Nối Mạng Cần Thiết (Whitelist)

Trước khi cài đặt, hãy đảm bảo hệ thống mạng / firewall / proxy của bạn cho phép truy cập tới các domain sau qua **Port 443 (HTTPS)**:

| Nhóm chức năng | Domain / Hostname | Mục đích | Bắt buộc |
| :--- | :--- | :--- | :---: |
| **Xác thực (OAuth2)** | `accounts.google.com` | Giao diện đăng nhập Google trên trình duyệt | ✅ |
| | `oauth2.googleapis.com` | Cấp và làm mới Token xác thực | ✅ |
| | `auth.cloud.google` | Xác thực dịch vụ Google Cloud | ✅ |
| | `sts.googleapis.com` | Google Security Token Service | ✅ |
| **AI & Backend** | `antigravity.google` | Máy chủ nền tảng Antigravity | ✅ |
| | `cloudcode-pa.googleapis.com` | Gateway API xử lý Agent & Code Assist | ✅ |
| | `generativelanguage.googleapis.com` | Gemini API Backend | ✅ |
| | `aicode.googleapis.com` | AI Code Generation API | ✅ |
| | `aiplatform.googleapis.com` | Vertex AI API (Doanh nghiệp / GCP) | ✅ |
| | `www.googleapis.com` | Google APIs Gateway chung | ✅ |
| **Tài nguyên tĩnh** | `www.gstatic.com` | Tải script / giao diện đăng nhập Google | ✅ |
| | `safebrowsing.googleapis.com` | Kiểm tra an toàn bảo mật web | Tuỳ chọn |

> **Lưu ý:**
> * Cổng mạng: **443 (HTTPS)** và **80 (HTTP)**.
> * Cần hỗ trợ **HTTP/2** hoặc **gRPC streaming** để nhận phản hồi theo thời gian thực từ AI.
> * Cần cho phép mở port local tạm thời trên `127.0.0.1` để trình duyệt trả OAuth token về CLI.

---

## 3. Kiểm Tra Kết Nối Mạng (Pre-flight Network Check)

Trước khi cài đặt, hãy chạy 1 trong 2 script sau trong PowerShell để biết mạng của bạn có bị chặn domain nào hay không:

### Trường hợp A: Mạng kết nối trực tiếp (Không dùng Proxy)
Mở PowerShell trong thư mục này và chạy:
```powershell
.\check_connection.ps1
```
*(Hoặc: `powershell -ExecutionPolicy Bypass -File .\check_connection.ps1`)*

### Trường hợp B: Mạng doanh nghiệp có dùng Proxy
Mở PowerShell và chạy:
```powershell
.\check_connection_proxy.ps1
```
Script sẽ yêu cầu bạn nhập địa chỉ Proxy (Ví dụ: `http://proxy.company.com:8080`).

---

## 4. Hướng Dẫn Cài Đặt Trên Máy Mới

### Cách 1: Tự động (Khuyên dùng)
* **Cách nhanh nhất:** Nhấp đúp chuột vào file `install.bat`.
* **Hoặc bằng PowerShell:**
  ```powershell
  .\install.ps1
  ```
  *(Script sẽ tự động copy `agy.exe` vào `%LOCALAPPDATA%\agy\bin` và cấu hình biến môi trường `PATH`).*

### Cách 2: Cài đặt thủ công
1. Tạo thư mục: `%LOCALAPPDATA%\agy\bin` (tức `C:\Users\<User>\AppData\Local\agy\bin`).
2. Copy file `bin\agy.exe` vào thư mục vừa tạo.
3. Thêm đường dẫn `%LOCALAPPDATA%\agy\bin` vào biến môi trường `PATH` của tài khoản (User Environment Variables).

---

## 5. Khởi Động & Đăng Nhập

1. Mở một cửa sổ **PowerShell** hoặc **CMD** **MỚI**.
2. Kiểm tra phiên bản:
   ```cmd
   agy --version
   ```
3. Khởi động CLI:
   ```cmd
   agy
   ```
4. Ở lần đầu chạy, terminal sẽ hiển thị link xác thực đăng nhập Google. Hãy làm theo hướng dẫn trên màn hình.

---

## 6. Cấu Hình Proxy Khi Sử Dụng (Nếu Có)

Nếu mạng của bạn cần Proxy để ra Internet, hãy set biến môi trường trước khi chạy `agy`:

**Trên PowerShell:**
```powershell
$env:HTTP_PROXY = "http://proxy.company.com:8080"
$env:HTTPS_PROXY = "http://proxy.company.com:8080"
agy
```

**Trên Command Prompt (CMD):**
```cmd
set HTTP_PROXY=http://proxy.company.com:8080
set HTTPS_PROXY=http://proxy.company.com:8080
agy
```
