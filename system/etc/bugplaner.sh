#!/system/bin/sh

# Konfigurasi
HOSTS=("quiz.int.vidio.com" "google.com" "8.8.8.8") # Daftar host untuk ping
TEST_URLS=("http://quiz.int.vidio.com" "https://www.google.com") # Daftar URL untuk tes koneksi
DURATION=4 # Durasi mode pesawat dalam detik
RETRY_LIMIT=4 # Jumlah percobaan sebelum mengaktifkan mode pesawat
POST_AIRPLANE_MODE_DELAY=10 # Jeda setelah mematikan mode pesawat
CONNECTION_CHECK_RETRIES=3 # Jumlah percobaan pengecekan koneksi setelah mode pesawat

MODPATH=${0%/*}
LOGFILE="/data/adb/modules/bugplaner/system/etc/magisk-log.txt"

failed_count=0

# Fungsi untuk menulis log dengan timestamp
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Fungsi untuk mengaktifkan tethering hotspot dan USB menggunakan pengaturan sistem dan iptables
enable_tethering() {
  log "Mengaktifkan tethering..."

  # Aktifkan Wi-Fi untuk hotspot
  svc wifi enable

  # Aktifkan tethering USB
  echo 'enable' > /sys/class/android_usb/android0/state
  echo 'rndis' > /sys/class/android_usb/android0/functions

  # Aktifkan tethering hotspot
  echo '1' > /proc/net/ipv4/ip_forward

  # Konfigurasi iptables untuk tethering
  iptables -t nat -A POSTROUTING -j MASQUERADE
  iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN -j TCPMSS --set-mss 1441

  log "Tethering diaktifkan."
}

# Fungsi untuk menonaktifkan tethering
disable_tethering() {
  log "Menonaktifkan tethering..."

  # Menonaktifkan tethering USB
  echo 'disable' > /sys/class/android_usb/android0/state

  # Menonaktifkan tethering hotspot
  iptables -t nat -F POSTROUTING
  iptables -t mangle -F FORWARD

  log "Tethering dinonaktifkan."
}

# Fungsi untuk mengecek koneksi
check_connection() {
  for host in "${HOSTS[@]}"; do
    if ping -c 1 "$host" > /dev/null; then
      log "Host $host dapat dijangkau."
      for url in "${TEST_URLS[@]}"; do
        if curl --silent --head --fail --connect-timeout 5 "$url" > /dev/null; then
          log "Koneksi ke $url aktif."
          return 0 # Koneksi aktif
        else
          log "Koneksi ke $url gagal."
        fi
      done
      return 0 # Koneksi aktif (ping berhasil, tapi mungkin ada masalah dengan URL tertentu)
    else
      log "Host $host tidak dapat dijangkau."
    fi
  done
  return 1 # Tidak ada koneksi
}

# Memastikan tethering aktif saat skrip pertama kali dijalankan
enable_tethering

while true; do
  if check_connection; then
    failed_count=0 # Reset counter jika koneksi data aktif
  else
    failed_count=$((failed_count+1))
  fi

  if [ $failed_count -ge $RETRY_LIMIT ]; then
    log "Koneksi gagal sebanyak $RETRY_LIMIT kali, mengaktifkan mode pesawat."
    settings put global airplane_mode_on 1
    am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true
    sleep $DURATION

    log "Mematikan mode pesawat."
    settings put global airplane_mode_on 0
    am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false

    log "Menunggu $POST_AIRPLANE_MODE_DELAY detik agar data aktif."
    sleep $POST_AIRPLANE_MODE_DELAY

    # Pengecekan koneksi setelah mode pesawat
    connection_check_retries=$CONNECTION_CHECK_RETRIES
    while [ $connection_check_retries -gt 0 ]; do
      if check_connection; then
        break
      else
        log "Menunggu koneksi aktif ($connection_check_retries)..."
        sleep 5
        connection_check_retries=$((connection_check_retries-1))
      fi
    done

    if check_connection; then
      enable_tethering # Aktifkan tethering setelah mode pesawat dan koneksi aktif
      failed_count=0 # Reset counter setelah mode pesawat
    else
      log "Koneksi masih gagal setelah mode pesawat. Memeriksa kembali nanti."
    fi
  fi

  sleep 1 # Tunggu 1 detik sebelum mencoba ping lagi
done
