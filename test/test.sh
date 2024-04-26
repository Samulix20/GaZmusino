RED='\e[31m'
GREEN='\e[32m'
NC='\e[0m'

cd isa_tests
rv_tests=$(ls base/base.S rv32ui/*.S)
cd ..

i=1
num_tests=$(echo "$rv_tests" | wc -l)
num_pass=0
num_fail=0

echo "Running $num_tests isa_tests..."
echo ""

for test in $rv_tests
do
    make -s -C isa_tests TEST_TARGET=$test 2>/dev/null
    make_status=$?

    if [ $make_status -ne 0 ]; then
        echo -e "$RED Error building test $NC"
        exit "$make_status"
    fi

    test_res=$(../obj_dir/Vrv32_core +verilator+rand+reset+2\
                -e ../build/isa_tests/${test%.S}.elf 2>&1)
    test_status=$?

    if [ $test_status -ne 0 ]; then
        echo -e "$i/$num_tests\t $test\t ${RED}FAIL $test_status ${NC}"
        echo -e "$test_res"
        num_fail=$((num_fail+1))
    else
        #echo -e "$i/$num_tests\t $test\t ${GREEN}PASS ${NC}"
        num_pass=$((num_pass+1))
    fi

    i=$((i+1))
done

echo ""
if [ $num_fail -ne 0 ]; then
    echo -e "${RED}$num_fail TEST FAILED${NC}"
    echo -e "${GREEN}$num_pass TEST PASSED${NC}"
else
    echo -e "${GREEN}ALL TEST PASSED${NC}"
fi
