rv_tests=$(ls base/base.S rv32ui/*.S rv32mi/*.S rv32um/*.S)

for test in $rv_tests
do
    make TEST_TARGET=$test
done
