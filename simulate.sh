# $1 must be a src directory file

# Get source files
srcs="$(find $1 -name '*.c') $(find $1 -name '*.S') $(find $1 -name '*.cpp')"

# Remove previous built simulation elf
rm -rf build/sim

# Compile source files + bsp and store results in build/sim
bash bsp/compiler.sh -b build/sim -f "-I $1/libs" $srcs

# Build CPU using verilator
make

# Run simulation
echo ""
./obj_dir/Vrv32_top -e build/sim/main.elf
