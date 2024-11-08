

all:
	./mipi-dbi-cmd rpi-dm-yt350s006.bin rpi-dm-yt350s006.txt
	./mipi-dbi-cmd rpi-dm-hp35006.bin rpi-dm-hp35006.txt
	dtc -@ -Hepapr -I dts -O dtb -o goodix-gt911.dtbo goodix-gt911.dts
	dtc -@ -Hepapr -I dts -O dtb -o ti-tsc2007.dtbo ti-tsc2007.dts

install:
	@echo "Installing..."

uninstall:
	@echo "Uninstalling.."

.PHONY:
clean:
	rm -rf *.bin *.dtbo
