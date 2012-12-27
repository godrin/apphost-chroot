all:
	./makefs.sh

clean:
	fusermount -u mp || echo "ok"
	rm -rf build prepare mp disk.img deps
