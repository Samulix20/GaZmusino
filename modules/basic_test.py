import sys, os

import build

import yaml

RED = "\033[31m"
GREEN = "\033[32m"
BOLD = '\033[1m'
UNDERLINE='\033[4m'
NC='\033[0m'

isa_test_path = "test/isa_tests"
isa_macros_path = f"{isa_test_path}/macros"
test_groups_list = ["base", "rv32ui", "rv32zicsr", "rv32mul"]

isa_test_buildir = "build/isa_tests"
exe_path = f"{isa_test_buildir}/test.elf"

def comp_isa_test(src):
    os.system(f"mkdir -p {isa_test_buildir}")
    obj = build.rvcomp(src, isa_test_buildir, f"-I{isa_macros_path}")
    build.rvlink([src], [obj], f"{isa_macros_path}/linker.lds", exe_path, "-nostdlib")

def run_isa_test(testname):
    test_res_path = f"{isa_test_buildir}/._isa_test_res.yaml"
    
    os.system(f"""
        ./obj_dir/Vrv32_top -e {exe_path} --prof "{test_res_path}"
    """)
    
    test_result = -1
    with open(test_res_path, 'r') as file:
        test_result = yaml.safe_load(file)
        test_result = test_result['exit_status']

    if testname == "fail.S":
        # fail.S test is supposed to fail so if it fails its ok
        if test_result != 0:
            test_result = 0
        else:
            # if it doesnt fail then something is wrong
            test_result = -1

    if test_result != 0:
        print(f"{RED}TEST: {testname} FAILED{NC}")
        print(f"EXIT STATUS {test_result}")
        print("")
        return False

    return True

def print_results(num_test, num_pass, num_fail):
    if(num_fail != 0):
        print(f"{UNDERLINE}RESULTS{NC}")
        print(f"{RED}[{num_fail}/{num_test}] TEST FAILED{NC}")
        print(f"{GREEN}[{num_pass}/{num_test}] TEST PASSED{NC}")
    else:
        print(f"{GREEN}ALL [{num_pass}/{num_test}] TESTS PASSED{NC}")
    print("")

def run_isa_test_folder(folder):
    num_pass = 0
    num_fail = 0
    num_test = 0
    test_path = f"{isa_test_path}/{folder}"
    
    print(f"{BOLD}STARTING {folder} TESTS...{NC}")
    
    for test in os.listdir(test_path):
        num_test += 1
        comp_isa_test(f"{test_path}/{test}")

        if run_isa_test(test):
            num_pass += 1
        else:
            num_fail += 1
    
    print_results(num_test, num_pass, num_fail)

examples_path = "examples"

def run_examples():

    print(f"{BOLD}RUNNING EXAMPLES...{NC}")

    for project in ["c_hello_world", "cpp_hello_world"]:
        
        print(f"{UNDERLINE}Example {project}{NC}")
        build.build_and_run(f"{examples_path}/{project}", "build")
        print("")


if __name__ == "__main__":
    build.log_enabled = False

    build.shell("make")

    for test_group in test_groups_list:
        run_isa_test_folder(test_group)

    run_examples()

