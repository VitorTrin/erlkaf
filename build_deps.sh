#!/usr/bin/env bash

ROOT=$(pwd)
DEPS_LOCATION=deps
OS=$(uname -s)
KERNEL=$(echo $(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 | awk '{print $1;}') | awk '{print $1;}')
CPUS=`getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu`

# https://github.com/edenhill/librdkafka.git

LIBRDKAFKA_DESTINATION=librdkafka
LIBRDKAFKA_REPO=https://github.com/edenhill/librdkafka.git
LIBRDKAFKA_BRANCH=master
LIBRDKAFKA_REV=4ffe54b4f59ee5ae3767f9f25dc14651a3384d62
LIBRDKAFKA_SUCCESS=src/librdkafka.a

fail_check()
{
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "error with $1" >&2
        exit 1
    fi
}

CheckoutLib()
{
    if [ -f "$DEPS_LOCATION/$4/$5" ]; then
        echo "$4 fork already exist. delete $DEPS_LOCATION/$4 for a fresh checkout ..."
    else
        #repo rev branch destination

        echo "repo=$1 rev=$2 branch=$3"

        mkdir -p $DEPS_LOCATION
        pushd $DEPS_LOCATION

        if [ ! -d "$4" ]; then
            fail_check git clone -b $3 $1 $4
        fi

        pushd $4
        fail_check git checkout $2
        BuildLibrary $4
        popd
        popd
    fi
}

BuildLibrary()
{
    unset CFLAGS
    unset CXXFLAGS

    case $1 in
        $LIBRDKAFKA_DESTINATION)
            case $OS in
                Darwin)
                    brew install openssl lz4 zstd
                    OPENSSL_ROOT_DIR=$(brew --prefix openssl)
                    export CPPFLAGS=-I$OPENSSL_ROOT_DIR/include/
                    export LDFLAGS=-L$OPENSSL_ROOT_DIR/lib
                    ;;
            esac

            fail_check ./configure
            fail_check make -j $(CPUS)

            rm src/*.dylib
            rm src/*.so
            ;;
        *)
            ;;
    esac
}

CheckoutLib $LIBRDKAFKA_REPO $LIBRDKAFKA_REV $LIBRDKAFKA_BRANCH $LIBRDKAFKA_DESTINATION $LIBRDKAFKA_SUCCESS
