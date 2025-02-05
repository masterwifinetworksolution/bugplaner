#!/system/bin/sh

# Pastikan skrip dijalankan dengan hak akses root
if [ "$(whoami)" != "root" ]; then
  echo "Skrip ini harus dijalankan dengan hak akses root."
  exit 1
fi

# Konfigurasi
HOSTS=("isikan.bugmu.com") # Daftar host untuk ping
RETRY_LIMIT=5 # Jumlah percobaan sebelum mengaktifkan mode pesawat
AIRPLANE_MODE_DURATION=5 # Durasi mode pesawat dalam detik
POST_AIRPLANE_MODE_DELAY=15 # Jeda setelah mematikan mode pesawat

MODPATH=${0%/*}
LOGFILE="/data/adb/modules/bugplaner/system/etc/bugplaner-log.txt"

failed_count=0

# Fungsi untuk menulis log dengan timestamp
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Fungsi untuk mengaktifkan tethering hotspot dan USB
aktifkan_tethering() {
  log "Mengaktifkan tethering..."

  # Aktifkan tethering USB menggunakan perintah alternatif
  if svc usb getFunctions rndis enable; then
    log "Tethering USB diaktifkan menggunakan perintah svc."
  else
    log "Gagal mengaktifkan tethering USB menggunakan perintah svc."
  fi

  # Aktifkan tethering hotspot
  if [ -f /proc/sys/net/ipv4/ip_forward ]; then
    echo '1' > /proc/sys/net/ipv4/ip_forward
    log "IP forwarding diaktifkan."
  else
    log "File /proc/sys/net/ipv4/ip_forward tidak ditemukan. IP forwarding tidak dapat diaktifkan."
  fi

  # Konfigurasi iptables untuk tethering
  iptables -t nat -A POSTROUTING -j MASQUERADE
  iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST,ACK SYN -j TCPMSS --set-mss 1441
  log "IPTables dikonfigurasi."

  log "Tethering diaktifkan."
}

# Fungsi untuk mengecek koneksi
cek_koneksi() {
  for host in "${HOSTS[@]}"]; do
    if ping -c 1 "$host" > /dev/null; then
      log "Host $host dapat dijangkau."
      return 0 # Koneksi aktif
    else
      log "Host $host tidak dapat dijangkau."
    fi
  done
  return 1 # Tidak ada koneksi
}

# Memastikan tethering aktif saat skrip pertama kali dijalankan
aktifkan_tethering

# Fungsi untuk mengelola mode pesawat
kelola_mode_pesawat() {
  log "Koneksi gagal sebanyak $RETRY_LIMIT kali, mengaktifkan mode pesawat."
  settings put global airplane_mode_on 1
  am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true
  sleep $AIRPLANE_MODE_DURATION

  log "Mematikan mode pesawat."
  settings put global airplane_mode_on 0
  am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false

  log "Menunggu $POST_AIRPLANE_MODE_DELAY detik agar data aktif."
  sleep $POST_AIRPLANE_MODE_DELAY

  # Reset counter setelah mode pesawat
  failed_count=0

  # Pastikan tethering aktif setelah mode pesawat dimatikan
  aktifkan_tethering
}

while true; do
  if cek_koneksi; then
    failed_count=0 # Reset counter jika koneksi data aktif
  else
    failed_count=$((failed_count+1))
  fi

  if [ $failed_count -ge $RETRY_LIMIT ]; then
    kelola_mode_pesawat
  fi

  sleep 1 # Tunggu 1 detik sebelum mencoba ping lagi
done
