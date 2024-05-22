RED='\e[31m'
GREEN='\e[32m'
NC='\e[0m'

# ISA TEST SECTION

cd isa_tests
rv_tests="$(ls base/base.S rv32ui/*.S) $(ls rv32um/*.S | grep -E mul)"
cd ..

i=1
num_tests=$(echo "$rv_tests" | wc -l)
num_pass=0
num_fail=0

echo "Running $num_tests isa_tests..."

for test in $rv_tests
do
    make -s -C isa_tests TEST_TARGET=$test 2>/dev/null
    make_status=$?

    if [ $make_status -ne 0 ]; then
        echo -e "$RED Error building test $NC"
        exit "$make_status"
    fi

    test_res=$(../obj_dir/Vrv32_top +verilator+rand+reset+2\
                -e ../build/isa_tests/${test%.S}.elf 2>&1)
    test_status=$?

    if [ $test_status -ne 0 ]; then
        echo -e "$i/$num_tests\t $test\t ${RED}FAIL $test_status ${NC}"
        echo -e "$test_res"
        num_fail=$((num_fail+1))
    else
        num_pass=$((num_pass+1))
    fi

    i=$((i+1))
done

if [ $num_fail -ne 0 ]; then
    echo -e "${RED}$num_fail TEST FAILED${NC}"
    echo -e "${GREEN}$num_pass TEST PASSED${NC}"
else
    echo -e "${GREEN}ALL TEST PASSED${NC}"
fi

# C TEST SECTION

make -s -C ../bsp -f bsp.mk BUILD_DIR=../build/bsp

rv_tests=$(ls c_tests)
num_tests=$(echo "$rv_tests" | wc -l)

i=1
num_tests=$(echo "$rv_tests" | wc -l)
num_pass=0
num_fail=0

echo "Running $num_tests c_tests..."

for test in $rv_tests
do
    
    test_srcs=$(find c_tests/$test -name '*.c')
    
    bash ../bsp/compiler.sh -b ../build/c_tests/$test $test_srcs

    test_res=$(../obj_dir/Vrv32_top +verilator+rand+reset+2\
                -e ../build/c_tests/$test/main.elf 2>&1)
    test_status=$?
    
    if [ $test_status -ne 0 ]; then
        echo -e "$i/$num_tests\t $test\t ${RED}FAIL $test_status ${NC}"
        echo -e "$test_res"
        num_fail=$((num_fail+1))
    else
        num_pass=$((num_pass+1))
    fi

    i=$((i+1))
done

if [ $num_fail -ne 0 ]; then
    echo -e "${RED}$num_fail TEST FAILED${NC}"
    echo -e "${GREEN}$num_pass TEST PASSED${NC}"
else
    echo -e "${GREEN}ALL TEST PASSED${NC}"
fi

# CPP TEST SECTION

rv_tests=$(ls cpp_tests)
num_tests=$(echo "$rv_tests" | wc -l)

i=1
num_tests=$(echo "$rv_tests" | wc -l)
num_pass=0
num_fail=0

echo "Running $num_tests cpp_tests..."

for test in $rv_tests
do
    
    test_srcs=$(find cpp_tests/$test -name '*.cpp')
    
    bash ../bsp/compiler.sh -b ../build/cpp_tests/$test $test_srcs

    test_res=$(../obj_dir/Vrv32_top +verilator+rand+reset+2\
                -e ../build/cpp_tests/$test/main.elf 2>&1)
    test_status=$?
    
    if [ $test_status -ne 0 ]; then
        echo -e "$i/$num_tests\t $test\t ${RED}FAIL $test_status ${NC}"
        echo -e "$test_res"
        num_fail=$((num_fail+1))
    else
        num_pass=$((num_pass+1))
    fi

    i=$((i+1))
done

if [ $num_fail -ne 0 ]; then
    echo -e "${RED}$num_fail TEST FAILED${NC}"
    echo -e "${GREEN}$num_pass TEST PASSED${NC}"
else
    echo -e "${GREEN}ALL TEST PASSED${NC}"
fi
