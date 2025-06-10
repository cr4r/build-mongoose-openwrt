## 🕸️ Mongoose Web Server Builder for OpenWrt ARM64

Skrip bash otomatis untuk mengunduh SDK, membangun paket Mongoose Web Server (`.ipk`), dan memasangnya ke sistem OpenWrt berbasis ARM64.

> ⚙️ **Kompatibel dengan**: OpenWrt `24.10.0` - Target: `armsr/armv8` - Arsitektur: `aarch64_generic`

---

### 📌 Fitur Utama

* ✅ Deteksi otomatis file SDK dan `mongoose.c/.h`
* ✅ Unduh SDK OpenWrt jika belum tersedia
* ✅ Instalasi dependensi build secara otomatis
* ✅ Build fleksibel: bisa download, install, dan build terpisah atau sekaligus
* ✅ Port dan direktori web root bisa dikustomisasi
* ✅ Antarmuka CLI warna-warni untuk pengalaman yang lebih ramah pengguna
* ✅ Output `.ipk` siap di-install ke OpenWrt ARM64

---

### 📦 Paket yang Dibangun

Paket hasil build adalah:

* `mongoose` versi `7.12`
* Output: `/bin/packages/…/mongoose_<versi>_aarch64_generic.ipk`

---

### 📁 Struktur Proyek

```
.
├── build-mongoose.sh      # Skrip utama
├── openwrt-sdk/           # Folder SDK hasil ekstrak
│   └── package/
│       └── mongoose
│           ├── Makefile
│           └── src/
│               ├── mongoose.c (auto-download)
│               ├── mongoose.h (auto-download)
│               └── main.c (generated)
└── openwrt-sdk.tar.zst    # File SDK (opsional)
```

---

### ⚙️ Cara Penggunaan

#### 1. **Install Dependensi Build (Linux Host)**

```bash
./build-mongoose.sh -i
```

#### 2. **Unduh dan Ekstrak SDK (Jika Belum Ada)**

```bash
./build-mongoose.sh -d
```

#### 3. **Build Paket `.ipk`**

```bash
./build-mongoose.sh -b
```

#### 🔁 Kombinasi: Install + Download SDK + Build

```bash
./build-mongoose.sh -i -d -b
```

#### ⚡ Kustomisasi Port & Web Root

```bash
./build-mongoose.sh -b -p 8080 -r /www/html
```

---

### 🔧 Instalasi ke OpenWrt

Salin file `.ipk` hasil build ke router (via SCP), lalu install:

```bash
scp mongoose_*.ipk root@<IP-ROUTER>:/tmp
ssh root@<IP-ROUTER>
opkg install /tmp/mongoose_*.ipk
```

---

### 🚀 Menjalankan Mongoose di OpenWrt

Setelah di-install:

```bash
mongoose
```

Untuk menjalankan di background, gunakan:

```bash
mongoose &
```

---

### 🛠️ Konfigurasi Manual (Opsional)

Jika ingin mengganti port atau web root setelah build:

* Edit file `main.c` lalu build ulang.
* Atau buat init script atau service wrapper di OpenWrt.

---

### 📥 Sumber Mongoose

* [https://github.com/cesanta/mongoose](https://github.com/cesanta/mongoose)

---

### 💬 Kontribusi & Dukungan

Jika kamu punya ide, saran, atau perbaikan, silakan fork dan buat pull request.
Atau kamu bisa membuka issue jika menemukan masalah selama proses build atau instalasi.

---
