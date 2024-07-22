# $1 must be a src directory file

srcs="$(find $1 -name '*.c') $(find $1 -name '*.S') $(find $1 -name '*.cpp')"

rm -rf build/sim

bash bsp/compiler.sh -b build/sim -f "-I $1/libs" $srcs

make -s
./obj_dir/Vrv32_top -e build/sim/main.elf
