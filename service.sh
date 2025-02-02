#!/system/bin/sh

HOST="ISIKAN BUGMU DISINI"  # Ganti dengan alamat IP atau hostname yang ingin Anda ping
TEST_URL="http://ISIKAN BUGMU DISINI"  # Ganti dengan URL yang ingin Anda uji koneksinya jika ping berhasil
DURATION=4  # Durasi mode pesawat dalam detik
RETRY_LIMIT=4  # Jumlah percobaan sebelum mengaktifkan mode pesawat
POST_AIRPLANE_MODE_DELAY=10  # Jeda setelah mematikan mode pesawat untuk memastikan data aktif

failed_count=0

while true; do
  if ping -c 1 $HOST > /dev/null; then
    echo "Host $HOST dapat dijangkau." >> /data/adb/bugplaner/magisk-log.txt
    if curl --silent --head --fail $TEST_URL > /dev/null; then
      echo "Koneksi data aktif." >> /data/adb/bugplaner/magisk-log.txt
      failed_count=0  # Reset counter jika koneksi data aktif
    else
      echo "Koneksi data tidak aktif, menganggap gagal." >> /data/adb/bugplaner/magisk-log.txt
      failed_count=$((failed_count+1))
    fi
  else
    echo "Host $HOST tidak dapat dijangkau." >> /data/adb/bugplaner/magisk-log.txt
    failed_count=$((failed_count+1))
  fi

  if [ $failed_count -ge $RETRY_LIMIT ]; then
    echo "Host tidak dapat dijangkau sebanyak $RETRY_LIMIT kali, mengaktifkan mode pesawat." >> /data/adb/bugplaner/magisk-log.txt
    settings put global airplane_mode_on 1
    am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true
    sleep $DURATION
    echo "Mematikan mode pesawat." >> /data/adb/bugplaner/magisk-log.txt
    settings put global airplane_mode_on 0
    am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false
    echo "Menunggu $POST_AIRPLANE_MODE_DELAY detik agar data aktif." >> /data/adb/bugplaner/magisk-log.txt
    sleep $POST_AIRPLANE_MODE_DELAY
    failed_count=0  # Reset counter setelah mode pesawat
  fi

  sleep 1  # Tunggu 1 detik sebelum mencoba ping lagi
done
