#!/vendor/bin/sh
scriptname=${0##*/}
dbg_on=1
debug()
{
	[ $dbg_on ] && echo "Debug: $*"
}

notice()
{
	echo "$*"
	echo "$scriptname: $*" > /dev/kmsg
}

error_and_leave()
{
	local err_msg
	local err_code=$1
	case $err_code in
		1)  err_msg="Error: No response";;
		2)  err_msg="Error: in factory mode";;
		3)  err_msg="Error: calibration file not exist";;
		4)  err_msg="Error: the calibration sys file not show up";;
	esac
	notice "$err_msg"
	exit $err_code
}

bootmode=`getprop ro.bootmode`
if [ $bootmode == "mot-factory" ]
then
	error_and_leave 2
fi

laser_class_path=/sys/devices/virtual/laser
laser_product_string=$(ls $laser_class_path)
laser_product_path=$laser_class_path/$laser_product_string
debug "laser product path: $laser_product_path"

for laser_file in $laser_product_path/*; do
	if [ -f "$laser_file" ]; then
		chown root:system $laser_file
	fi
done

bootmode=$(getprop ro.bootmode 2> /dev/null)
if [ $bootmode != "mot-factory" ]; then
       # Enable smudge mode
       echo 1 > $laser_product_path/smudge_correction_mode
       notice "laser smudge mode enabled"
else
       # Disable laser smudge mode
       echo 0 > $laser_product_path/smudge_correction_mode
       notice "factory-mode boot, disable laser smudge mode"
fi

laser_offset_path=$laser_product_path/offset
laser_offset_string=$(ls $laser_offset_path)
debug "laser offset path: $laser_offset_path"
[ -z "$laser_offset_string" ] && error_and_leave 4

cal_offset_path=/mnt/vendor/persist/camera/focus/offset_cal
cal_offset_string=$(ls $cal_offset_path)
[ -z "$cal_offset_string" ] && error_and_leave 3

offset_cal=$(cat $cal_offset_path)
debug "offset cal value [$offset_cal]"

debug "set cal value to kernel"
echo $offset_cal > $laser_offset_path
notice "laser cal data update success"

