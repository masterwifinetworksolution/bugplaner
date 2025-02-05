#!/system/bin/sh

SKIPUNZIP=0
ASH_STANDALONE=1

ui_print "pindahkan file bugplaner.sh ke etc"
mv system/etc ${MODPATH}/system/etc

ui_print "pindahkan file module.prop ke folder module"
mv module.prop ${MODPATH}/module.prop

ui_print "pindahkan file service.sh ke folder module"
mv service.sh ${MODPATH}/service.sh

ui_print "pindahkan file module.json ke folder module"
mv module.json ${MODPATH}/module.json

ui_print "pindahkan file README.md ke folder module"
mv README.md ${MODPATH}/README.md

ui_print "cek permisions bugplaner.sh"
set_perm ${MODPATH}${file_path_system}/bugplaner.sh 0 0 0755

ui_print "cek permisions bugplaner-log.txt"
set_perm ${MODPATH}${file_path_system}/bugplaner-log.txt 0 0 0644

ui_print "cek permisions disable.sh"
set_perm ${MODPATH}${file_path_system}/disable.sh 0 0 0755

ui_print "cek permisions enable.sh"
set_perm ${MODPATH}${file_path_system}/enable.sh 0 0 0755

ui_print "cek permisions module.prop"
set_perm ${MODPATH}/module.prop 0 0 0644

ui_print "cek permisions service.sh"
set_perm ${MODPATH}/service.sh 0 0 0755

ui_print "cek permisions module.json"
set_perm ${MODPATH}/module.json 0 0 0644

ui_print "cek permisions README.md"
set_perm ${MODPATH}/README.md 0 0 0644

ui_print "- Installation is complete, reboot your device"
