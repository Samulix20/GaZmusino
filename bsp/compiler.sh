
CALL_PWD=$(pwd)
SCRIPT_PWD=$(realpath $(dirname $0))
BUILD_DIR=$CALL_PWD/build

while getopts ":b:p" opt; do
  case ${opt} in
    b)
        BUILD_DIR=$CALL_PWD/$OPTARG
        ;;
    :)
        echo "Option -${OPTARG} requires an argument."
        exit 1
        ;;
    ?)
        echo "Invalid option: -${OPTARG}."
        exit 1
        ;;
  esac
done

shift "$((OPTIND-1))"

# Build bsp
cd $SCRIPT_PWD
make -s -f bsp.mk \
    BUILD_DIR=$BUILD_DIR/bsp

# Build elf
cd $CALL_PWD
make -s -f $SCRIPT_PWD/c.mk\
    SRCS="$(echo $@)"\
    BUILD_DIR=$BUILD_DIR\
    BSP_DIR=$SCRIPT_PWD 2>/dev/null
