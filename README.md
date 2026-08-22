# Hướng Dẫn Cài Đặt Antigravity CLI (`agy`) Ngoại Tuyến / Di Động (Portable)

Tài liệu này hướng dẫn cách đưa gói cài đặt `agy` sang máy tính khác (kể cả máy bị chặn không tải được trực tiếp từ website `antigravity.google`).

---

## 1. Cấu trúc thư mục gói cài đặt

```text
agy_zip/
├── bin/
│   └── agy.exe         # File thực thi chính của Antigravity CLI (~184MB)
├── install.ps1         # Script cài đặt tự động bằng PowerShell
├── install.bat         # Script cài đặt tự động bằng Command Prompt (hoặc click đúp)
└── README.md           # Hướng dẫn chi tiết này
```

---

## 2. Cách cài đặt trên máy mới

Bạn có thể chọn **Cách 1 (Tự động - Khuyên dùng)** hoặc **Cách 2 (Thủ công)**:

### Cách 1: Cài đặt tự động (Nhanh nhất)

#### Cách A: Chạy file `.bat`
* Nhấp đúp chuột vào file `install.bat` (hoặc chuột phải chọn **Run as administrator** nếu cần).
* Chờ script hoàn tất và nhấn phím bất kỳ để đóng.

#### Cách B: Chạy qua PowerShell
1. Mở PowerShell trong thư mục `agy_zip`.
2. Chạy lệnh:
   ```powershell
   .\install.ps1
   ```
*(Nếu gặp lỗi Execution Policy, chạy lệnh: `powershell -ExecutionPolicy Bypass -File .\install.ps1`)*

---

### Cách 2: Cài đặt thủ công (Manual)

Nếu bạn không muốn chạy script tự động, hãy làm theo 3 bước sau:

1. **Tạo thư mục đích:**
   * Mở File Explorer, truy cập vào đường dẫn:
     ```text
     %LOCALAPPDATA%\agy\bin
     ```
     *(Thường là `C:\Users\<Tên_User>\AppData\Local\agy\bin` — nếu chưa có thư mục thì tự tạo mới).*

2. **Sao chép file:**
   * Copy file `bin\agy.exe` từ gói này dán vào thư mục `%LOCALAPPDATA%\agy\bin\`.

3. **Thêm vào biến môi trường PATH:**
   * Nhấn phím `Win + S` -> Gõ **Environment Variables** -> Chọn **Edit environment variables for your account**.
   * Trong phần **User variables**, chọn dòng `Path` -> Bấm **Edit** -> Bấm **New**.
   * Thêm đường dẫn: `%LOCALAPPDATA%\agy\bin` (hoặc đường dẫn đầy đủ dạng `C:\Users\<Tên_User>\AppData\Local\agy\bin`).
   * Bấm **OK** để lưu lại.

---

## 3. Khởi động và Đăng nhập

1. Mở một cửa sổ **PowerShell** hoặc **Command Prompt (CMD)** **MỚI** (để nhận PATH mới).
2. Gõ lệnh:
   ```cmd
   agy --version
   ```
   để kiểm tra phiên bản.
3. Gõ lệnh:
   ```cmd
   agy
   ```
   để bắt đầu phiên làm việc.
4. **Đăng nhập:** Ở lần chạy đầu tiên, màn hình terminal sẽ hiển thị hướng dẫn xác thực tài khoản Google (OAuth) qua trình duyệt. Hãy làm theo hướng dẫn để đăng nhập.

---

## 4. Xử lý sự cố mạng & Proxy (Dành cho mạng doanh nghiệp / Firewall)

`agy` là CLI giao tiếp với Google backend (Gemini / Antigravity Cloud). Do đó máy tính cần có kết nối ra internet để gửi/nhận phản hồi AI.

### Trường hợp mạng dùng Proxy:
Nếu máy của bạn sử dụng Corporate Proxy để ra ngoài Internet, hãy đặt biến môi trường Proxy trước khi chạy:

**Trên PowerShell:**
```powershell
$env:HTTP_PROXY = "http://proxy.company.com:8080"
$env:HTTPS_PROXY = "http://proxy.company.com:8080"
agy
```

**Trên CMD:**
```cmd
set HTTP_PROXY=http://proxy.company.com:8080
set HTTPS_PROXY=http://proxy.company.com:8080
agy
```

*(Hoặc cấu hình vĩnh viễn trong User Environment Variables).*

---

## 5. Một số thao tác nhanh trong CLI

* **Thoát CLI:** Nhấn `Ctrl + D` hai lần hoặc gõ `/exit` / `/quit`.
* **Trợ giúp:** Gõ `/help` trong CLI để xem tất cả các slash commands có sẵn.
* **Xem tham số CLI:** Gõ `agy --help` ngoài terminal.
