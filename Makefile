

all:
	./mipi-dbi-cmd rpi-dm-yt350s006.bin rpi-dm-yt350s006.txt
	./mipi-dbi-cmd rpi-dm-hp35006.bin rpi-dm-hp35006.txt
	./mipi-dbi-cmd rpi-dm-cl35bc219-40a.bin rpi-dm-cl35bc219-40a.txt
	./mipi-dbi-cmd rpi-dm-cl35bc1017-40a.bin rpi-dm-cl35bc1017-40a.txt
	dtc -@ -Hepapr -I dts -O dtb -o goodix-gt911.dtbo goodix-gt911.dts
	dtc -@ -Hepapr -I dts -O dtb -o focaltech-ft6236.dtbo focaltech-ft6236.dts
	dtc -@ -Hepapr -I dts -O dtb -o ti-tsc2007.dtbo ti-tsc2007.dts
	dtc -@ -Hepapr -I dts -O dtb -o nsiway-ns2009.dtbo nsiway-ns2009.dts

install:
	@echo "Installing..."

uninstall:
	@echo "Uninstalling.."

.PHONY:
clean:
	rm -rf *.bin *.dtbo
