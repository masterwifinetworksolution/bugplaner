#!/system/bin/sh

HOST="quiz.int.vidio.com"  # Ganti dengan alamat IP atau hostname yang ingin Anda ping
DURATION=4  # Durasi mode pesawat dalam detik
RETRY_LIMIT=4  # Jumlah percobaan sebelum mengaktifkan mode pesawat
POST_AIRPLANE_MODE_DELAY=10  # Jeda setelah mematikan mode pesawat untuk memastikan data aktif

failed_count=0

while true; do
  if ping -c 1 $HOST > /dev/null; then
    echo "Host $HOST dapat dijangkau." >> /data/local/tmp/magisk-log.txt
    failed_count=0  # Reset counter jika host dapat dijangkau
  else
    echo "Host $HOST tidak dapat dijangkau." >> /data/local/tmp/magisk-log.txt
    failed_count=$((failed_count+1))
    if [ $failed_count -ge $RETRY_LIMIT ]; then
      echo "Host tidak dapat dijangkau sebanyak $RETRY_LIMIT kali, mengaktifkan mode pesawat." >> /data/local/tmp/magisk-log.txt
      settings put global airplane_mode_on 1
      am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true
      sleep $DURATION
      echo "Mematikan mode pesawat." >> /data/local/tmp/magisk-log.txt
      settings put global airplane_mode_on 0
      am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false
      echo "Menunggu $POST_AIRPLANE_MODE_DELAY detik agar data aktif." >> /data/local/tmp/magisk-log.txt
      sleep $POST_AIRPLANE_MODE_DELAY
      failed_count=0  # Reset counter setelah mode pesawat
    fi
  fi
  sleep 1  # Tunggu 1 detik sebelum mencoba ping lagi
done
