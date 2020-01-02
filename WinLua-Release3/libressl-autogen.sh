cd /c/users/russh/Git/WInLua-Mk3/Sources/libressl
./autogen.sh
#~ //TODO: check if dir exists
#~ mkdir $1
cd $1
cmake -DBUILD_SHARED_LIBS=ON -G"$2" ..
