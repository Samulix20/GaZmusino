rv_tests=$(ls base/base.S rv32ui/*.S rv32mi/*.S rv32um/*.S)

rv_tests=$(echo "$rv_tests" | grep -E rv32ui)

for test in $rv_tests
do
    echo $test
    make -s TEST_TARGET=$test 2>/dev/null
    make_status=$?

    if [ $make_status -ne 0 ]; then
        echo Error building test
        exit $make_status
    fi

    test_res=$(../obj_dir/Vrv32_core +verilator+rand+reset+2 -e ../build/${test%.S}.elf)
    test_status=$?

    if [ $test_status -ne 0 ]; then
        echo $test_status
        echo $test_res
        exit 1
    fi
done
