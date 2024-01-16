#Testing with Ubuntu Image

##Run and Attach Container

```
CONTAINER_NAME="UbuntuTestImg"
docker pull ubuntu:jammy
sudo docker volume create LEAP_PATCH
# docker volume inspect LEAP_PATCH
docker create -it --name $CONTAINER_NAME -v LEAP_PATCH:/shared-vol --network=host ubuntu:jammy
docker start $CONTAINER_NAME
docker attach $CONTAINER_NAME
```

*Note: `sudo docker volume rm LEAP_PATCH` when finished

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
**Boost version**
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

###Update for Leap

```
apt install clang libboost-all-dev cmake openssl
apt install llvm-11
apt install curl zlib1g pip
pip install numpy
sudo apt-get install -y \
        libcurl4-openssl-dev \
        libgmp-dev \
        libssl-dev \
        llvm-11-dev
```
