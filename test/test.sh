# Runs all tests under isa_tests, c_tests and cpp_tests

RED='\e[31m'
GREEN='\e[32m'
NC='\e[0m'
BOLD='\e[1m'
UNDERLINE='\e[4m'

# Functions

# Vars/Parameters of the function
num_tests=0
num_pass=0
num_fail=0
print_test_results() {
    echo " "
    echo -e "${UNDERLINE}RESULTS${NC}"
    if [ $num_fail -ne 0 ]; then
        echo -e "${RED}[$num_fail/$num_tests] TEST FAILED${NC}"
        echo -e "${GREEN}[$num_pass/$num_tests] TEST PASSED${NC}"
    else
        echo -e "${GREEN}ALL [$num_pass/$num_tests] TEST PASSED${NC}"
    fi
    echo " "
}

test=""
test_result=""
test_status=0
check_test() {
    # Check test result
    if [ $test_status -ne 0 ]; then
        echo -e " "
        echo -e "${RED}$i/$num_tests\t $test\t FAIL $test_status ${NC}"
        echo -e "$test_result"
        num_fail=$((num_fail+1))
    else
        num_pass=$((num_pass+1))
    fi
}

test_folder=""
run_all_folder_tests() {
    rv_tests=$(ls $test_folder)
    num_tests=$(echo "$rv_tests" | wc -l)

    echo -e "${BOLD}STARTING $test_folder TESTS...${NC}"

    i=1
    num_pass=0
    num_fail=0

    for test in $rv_tests
    do
        
        test_srcs="$(find $test_folder/$test -name '*.c') $(find $test_folder/$test -name '*.cpp')"
        
        build_output=$(bash ../bsp/compiler.sh -b ../build/$test_folder/$test $test_srcs 2>&1)
        make_status=$?

        if [ $make_status -ne 0 ]; then
            echo " "
            echo -e "${RED}[$i] Error building test $test $NC"
            echo -e "$build_output"
            num_fail=$((num_fail+1))
        else
            test_res=$(../obj_dir/Vrv32_top +verilator+rand+reset+2\
                        -e ../build/$test_folder/$test/main.elf 2>&1)
            test_status=$?

            check_test
        fi

        i=$((i+1))
    done

    print_test_results
}

# ISA TEST SECTION

cd isa_tests
rv_tests="$(ls base/base.S rv32ui/*.S rv32zicsr/*.S rv32mul/*.S)"
cd ..

i=1
num_tests=$(echo "$rv_tests" | wc -l)
num_pass=0
num_fail=0

echo " "
echo -e "${BOLD}STARTING $num_tests ISA TESTS...${NC}"

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
        test_result=$(../obj_dir/Vrv32_top +verilator+rand+reset+2\
                    -e ../build/isa_tests/${test%.S}.elf 2>&1)
        test_status=$?
        check_test
    fi

    i=$((i+1))
done

print_test_results

# BSP TEST BUILD SECTION

build_output=$(make -C ../bsp -f bsp.mk BUILD_DIR=../build/bsp 2>&1)
make_status=$?
if [ $make_status -ne 0 ]; then
    echo -e "${RED}[!!] Error building BSP $NC"
    echo -e "$build_output"
    exit $make_status
fi

# C TEST SECTION

test_folder="c_tests"
run_all_folder_tests

# CPP TEST SECTION

test_folder="cpp_tests"
run_all_folder_tests

