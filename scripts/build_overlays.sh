#!/bin/bash                                                                                                                              
# restart script with root privileges if not already
[ "$UID" -eq 0 ] || exec sudo "$0" "$@" ]

patch_dir="$(pwd)/patches/overlays"
output_dir="$(pwd)/output"
overlays_dir="${output_dir}/overlays"

mkdir -p "${overlays_dir}"

# overlays array
declare -a overlays=("JN-24LCD-FEATHERWING" 
					"JN-35LCD-FEATHERWING"
					"JN-ADC"
					"JN-ETHERNET-FEATHERWING"
					"JN-I2C0"
					"JN-I2S0"
					"JN-I2S0-NO-MCK"
					"JN-I2S0-NO-MCK-NO-DI"
					"JN-PWM1"
					"JN-PWM1-3"
					"JN-PWM2"
					"JN-SPI0-ENC28J60"
					"JN-SPI0-SPIDEV-CS-PWML1"
					"JN-SPI0-SPIDEV-NO-CS"
					"JN-WIFI-FEATHERWING"
					"JN-UART2-FLX4-AD2-AD3")

# Install all the libs listed in the blinka_libs array
#dtc -@ -I dts -O dtb -o ${overlays_dir}/"$i".dtbo ${patch_dir}/"$i".dts

for i in "${overlays[@]}"
do
	cpp -Iinclude -E -P -x assembler-with-cpp ${patch_dir}/"$i".dts | dtc -@ -I dts -O dtb -o ${overlays_dir}/"$i".dtbo
done

echo "done building.."
