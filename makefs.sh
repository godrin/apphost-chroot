#!/bin/bash
pwd=$(pwd)
prefix=${pwd}/prepare


umask 0022

echo "Clean up...."
fusermount -u mp

rm -rf mount mp test disk.img prepare

echo "Create prepare-dir"
mkdir -p ${prefix}


echo "install ruby"

mkdir build
cd build
test -e ruby-1.9.3-p327.tar.bz2 || wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p327.tar.bz2

if [ ! -e ruby-1.9.3-p327 ] ; then
  #rm -rf ruby-1.9.3-p327
  tar xfj ruby-1.9.3-p327.tar.bz2
  cd ruby-1.9.3-p327
  ./configure --prefix=/usr/ruby1.9.3 --disable-install-doc
else
  cd ruby-1.9.3-p327
fi
make
make DESTDIR=${prefix} install
cd ${pwd}
mkdir -p ${prefix}/bin ${prefix}/lib ${prefix}/usr/bin ${prefix}/proc

prgs='/bin/ps /bin/bash /bin/ls /bin/grep /bin/less /bin/cat /usr/bin/whoami /usr/bin/strace'

data="/etc/default/nss /etc/nsswitch.conf"

for d in ${data} ; {
  mkdir -p ${prefix}/$(dirname $d)
  cp -av $d ${prefix}/$d
}

for prg in ${prgs} ; {
  mkdir -p ${prefix}/$(dirname $prg)
  echo cp -av ${prg} ${prefix}/${prg}
  cp -av ${prg} ${prefix}/${prg}
}


test -e  ${prefix}/usr/ruby1.9.3/bin/ruby || { echo "Ruby not compiled correctly!" ; exit 1 ; }

ldd ${prgs} ${prefix}/usr/ruby1.9.3/bin/ruby |sed -e "s/.*=>//" -e "s/(.*//">deps
for a in $(cat deps) ;  {
  echo $a
  d=$(dirname $a)
  mkdir -p ${prefix}$d
  echo cp $a ${prefix}/$a
  cp $a ${prefix}/$a
}

cp /lib/i386-linux-gnu/lib*nsl* /lib/i386-linux-gnu/lib*nss*  ${prefix}/lib/i386-linux-gnu/

mkdir -p ${prefix}/etc
echo "root:x:0:0:root:/root:/bin/bash">${prefix}/etc/passwd
echo "david:x:1000:1000:david,,,:/home/david:/bin/bash">>${prefix}/etc/passwd

echo "root:x:0:">${prefix}/etc/group
echo "david:x:1000:">>${prefix}/etc/group

touch ${prefix}/ready






echo "make image...."
mksquashfs ${prefix} disk.img -all-root


echo "mount image..."
mkdir -p mp
~/puppet/squashfs/usr/bin/squashfuse -o allow_root disk.img mp


echo "enter chroot"
sudo chroot mp




