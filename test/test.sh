# Runs all tests under isa_tests, c_tests and cpp_tests

RED='\e[31m'
GREEN='\e[32m'
NC='\e[0m'

# ISA TEST SECTION

cd isa_tests
rv_tests="$(ls base/base.S rv32ui/*.S rv32zicsr/*.S rv32mul/*.S)"
cd ..

i=1
num_tests=$(echo "$rv_tests" | wc -l)
num_pass=0
num_fail=0

echo "STARTING $num_tests ISA TESTS... "

for test in $rv_tests
do
    # Build the test
    build_output=$(make -C isa_tests TEST_TARGET=$test 2>&1)
    make_status=$?

    # Check build result
    if [ $make_status -ne 0 ]; then
        echo " "
        echo -e "${RED}[$i] Error building test $test $NC"
        echo -e "$build_output"
        num_fail=$((num_fail+1))
    else
        # Run simulation
        test_res=$(../obj_dir/Vrv32_top +verilator+rand+reset+2\
                    -e ../build/isa_tests/${test%.S}.elf 2>&1)
        test_status=$?

        # Check test result
        if [ $test_status -ne 0 ]; then
            echo -e " "
            echo -e "${RED}$i/$num_tests\t $test\t FAIL $test_status ${NC}"
            echo -e "$test_res"
            num_fail=$((num_fail+1))
        else
            num_pass=$((num_pass+1))
        fi
    fi

    i=$((i+1))
done

echo " "
echo "RESULTS"
if [ $num_fail -ne 0 ]; then
    echo -e "${RED}[$num_fail/$num_tests] TEST FAILED${NC}"
    echo -e "${GREEN}[$num_pass/$num_tests] TEST PASSED${NC}"
else
    echo -e "${GREEN}ALL [$num_pass/$num_tests] TEST PASSED${NC}"
fi

echo " "

# C TEST SECTION

make -s -C ../bsp -f bsp.mk BUILD_DIR=../build/bsp

rv_tests=$(ls c_tests)
num_tests=$(echo "$rv_tests" | wc -l)

i=1
num_tests=$(echo "$rv_tests" | wc -l)
num_pass=0
num_fail=0

echo "STARTING $num_tests C TESTS... "

for test in $rv_tests
do
    
    test_srcs=$(find c_tests/$test -name '*.c')
    
    bash ../bsp/compiler.sh -b ../build/c_tests/$test $test_srcs

    test_res=$(../obj_dir/Vrv32_top +verilator+rand+reset+2\
                -e ../build/c_tests/$test/main.elf 2>&1)
    test_status=$?
    
    if [ $test_status -ne 0 ]; then
        echo " "
        echo -e "$i/$num_tests\t $test\t ${RED}FAIL $test_status ${NC}"
        echo -e "$test_res"
        num_fail=$((num_fail+1))
    else
        num_pass=$((num_pass+1))
    fi

    i=$((i+1))
done

echo " "
echo "RESULTS"
if [ $num_fail -ne 0 ]; then
    echo -e "${RED}$num_fail TEST FAILED${NC}"
    echo -e "${GREEN}$num_pass TEST PASSED${NC}"
else
    echo -e "${GREEN}ALL [$num_pass/$num_tests] TEST PASSED${NC}"
fi

echo " "

# CPP TEST SECTION

rv_tests=$(ls cpp_tests)
num_tests=$(echo "$rv_tests" | wc -l)

i=1
num_tests=$(echo "$rv_tests" | wc -l)
num_pass=0
num_fail=0

echo "STARTING $num_tests C++ TESTS... "

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

echo " "
echo "RESULTS"
if [ $num_fail -ne 0 ]; then
    echo -e "${RED}$num_fail TEST FAILED${NC}"
    echo -e "${GREEN}$num_pass TEST PASSED${NC}"
else
    echo -e "${GREEN}ALL [$num_pass/$num_tests] TEST PASSED${NC}"
fi

echo " "
