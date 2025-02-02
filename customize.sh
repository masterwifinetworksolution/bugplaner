#!/system/bin/sh

SKIPUNZIP=1
ASH_STANDALONE=1

# Direktori tujuan
file_path="/system/etc"

# Periksa apakah instalasi dilakukan melalui Magisk
if $BOOTMODE; then
  ui_print "- Installing bugplaner from Magisk app"
else
  ui_print "*********************************************************"
  ui_print "! Install from recovery is NOT supported"
  ui_print "! Please install bugplaner from Magisk app"
  abort "*********************************************************"
fi

# Pindahkan file ke /system/etc
ui_print "- Moving files to /system/etc"
mkdir -p ${MODPATH}${file_path}
mv -f ${MODPATH}/bugplaner.sh ${MODPATH}${file_path}/bugplaner.sh
mv -f ${MODPATH}/bugplaner-log.txt ${MODPATH}${file_path}/bugplaner-log.txt

# Set permissions
ui_print "- Setting permissions"
set_perm ${MODPATH}${file_path}/bugplaner.sh 0 0 0755
set_perm ${MODPATH}${file_path}/bugplaner-log.txt 0 0 0644

# Bersihkan file yang tidak diperlukan
ui_print "- Cleaning up"
rm -rf ${MODPATH}/bugplaner.sh
rm -rf ${MODPATH}/bugplaner-log.txt

ui_print "- Installation is complete, reboot your device"