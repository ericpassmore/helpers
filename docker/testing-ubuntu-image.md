#Testing with Ubuntu Image

##Run and Attach Container

```
CONTAINER_NAME="chronicle"
docker pull ubuntu:jammy
docker create -it --name $CONTAINER_NAME --network=host ubuntu:jammy
docker start $CONTAINER_NAME
docker attach $CONTAINER_NAME
```

##Update

###Update Name Services
```
sed 's/10.12.0.1/1.1.1.1/' /etc/resolv.conf > /tmp/new.resolve.conf
cp /etc/resolv.conf /tmp/orig.resolve.conf
cp /tmp/new.resolve.conf /etc/resolv.conf
```
###Update Packages
```
apt update
apt install git wget
```

###Updates for C++
**Dev Tools**
```
apt install build-essential g++ python3-dev autotools-dev libicu-dev libbz2-dev libboost-all-dev
```
**Cmake**
```
apt install cmake
```
**Boost**
```
mkdir -p /opt/src/
cd /opt/src || exit
MAJOR=1
MINOR=67
PATCH=0
wget https://boostorg.jfrog.io/artifactory/main/release/${MAJOR}.${MINOR}.${PATCH}/source/boost_${MAJOR}_${MINOR}_${PATCH}.tar.gz
tar xvf boost_${MAJOR}_${MINOR}_${PATCH}.tar.gz
cd boost_${MAJOR}_${MINOR}_${PATCH} || exit
./bootstrap.sh --prefix=/usr/
./b2 install
```

**ENV-Vars**
The Boost C++ Libraries were successfully built!
The following directory should be added to compiler include paths:
`/opt/src/boost_1_67_0`

The following directory should be added to linker library paths:

`/opt/src/boost_1_67_0/stage/lib`
