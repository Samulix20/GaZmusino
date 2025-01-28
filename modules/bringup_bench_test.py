import sys, os

import build
import basic_test

import shutil
import filecmp
import argparse
from pathlib import Path

RED = "\033[31m"
GREEN = "\033[32m"
BOLD = '\033[1m'
NC='\033[0m'

path_testbench = "test/bringup-bench"
path_common = path_testbench + "/common"
path_target = path_testbench + "/target"
path_build = "build/bringup-bench"
common_headers = ["libmin.h", "libtarg.h"]

# Lists of all tests
short_tests = ["ackermann", "audio-codec", "avl-tree", "banner", "blake2b", "boyer-moore-search", "bubble-sort", "cipher", "dhrystone", "distinctness", "fft-int", "flood-fill", "frac-calc", "fuzzy-match",
               "fy-shuffle", "gcd-list", "graph-tests", "hanoi", "heapsort", "indirect-test", "kadane", "kepler", "knapsack", "knights-tour", "knights-tour", "longdiv", "max-subseq", "mersenne", "minspan", "murmur-hash",
               "pascal", "priority-queue", "qsort-demo", "quaternions", "quine", "rabinkarp-search", "regex-parser", "rle-compress", "shortest-path", "sieve", "simple-grep", "skeleton", "topo-sort", "totient",
               "vectors-3d", "weekday", "bloom-filter", "grad-descent", "k-means", "nr-solver", "parrondo", "spirograph", "life", "primal-test"]

long_tests = ["rho-factor", "mandelbrot", "natlog", "satomi", "pi-calc", "tiny-NN"]
error_tests = ["anagram", "checkers" , "spelt2num", "strange", "donut"]

#Adds libmin.h and libtarg.h to the target directory
def add_common_headers(target):
    for file in common_headers:
        source_item = os.path.join(path_common, file)
        target_item = os.path.join(target, file)
        
        if not os.path.exists(target_item):  # Copiar solo si no existe
            shutil.copy2(source_item, target_item)

# Removes libmin.h and libtarg.h from the specified directory
def remove_common_headers(dirname):
    for file in common_headers:
        file_path = os.path.join(dirname, file)
        if os.path.exists(file_path):  
            os.remove(file_path)      

# Check if the output of the test is the expexted 
def check_test(dirname):
    archivos_out = [archivo for archivo in os.listdir(dirname) if archivo.endswith(".out")]
    
    if filecmp.cmp(dirname + "/" + archivos_out[0], dirname + "/" + archivos_out[1], shallow=False):
        os.remove(dirname + "/output.out")
        return True
    else:
        return False

def add_target_files_to_common():
    for file in os.listdir(path_target):
        if file.endswith(".c") or file.endswith(".h"):
            shutil.copy2(os.path.join(path_target, file), path_common)

# Build, Link, Run 
def compile_and_link_test_bringup_bench(testdir, buildir, targetname, *extra_args):
    bsp_srcs, bsp_objs, lds = build.compile_bsp(f"{buildir}/{testdir}/bsp")
    common_srcs, common_objs = build.compile_dir(path_common,f"{buildir}/{testdir}/common")
    srcs, objs = build.compile_dir(testdir, f"{buildir}/{testdir}", *extra_args)
    target = f"{buildir}/{testdir}/{targetname}"
    build.rvlink(srcs, bsp_objs + objs + common_objs, lds, target)

def run_test_bringup_bench(testdir, logfile, *extra_args):
    compile_and_link_test_bringup_bench(testdir, "build", "main.elf", *extra_args)
    os.system(f"""
        ./obj_dir/Vrv32_top -e build/{testdir}/main.elf --out {logfile} > /dev/null
    """)

#Run all test on bringup-bench
def run_tests(sub_dirs):
    print(f"{BOLD}RUNNING BRINGUP-BENCH...{NC}")
    
    add_target_files_to_common()
    num_test = 0
    num_pass = 0
    num_fail = 0

    clearterm = f"\r{" "*80}\r"

    for sub_dir in sub_dirs:
        print(clearterm, end='')
        print(f"[{num_test + 1}/{len(sub_dirs)}] Running {sub_dir}", end='', flush=True)
        
        add_common_headers(sub_dir)
        run_test_bringup_bench(sub_dir, sub_dir + "/output.out", "-D", "TARGET_HOST") # Build and run test
        remove_common_headers(sub_dir)

        if(check_test(sub_dir)):
            num_pass += 1
        else:
            num_fail += 1
            print(clearterm, end='')
            print(f"{RED}TEST: " + sub_dir + " FAIL")
            print("CHECK " + sub_dir + "/output.out")
            print(f"{NC}")
        
        num_test += 1
    
    print(clearterm, end='')
    basic_test.print_results(num_test, num_pass, num_fail)
    
if __name__ == "__main__":
    build.shell("make")
    parser = argparse.ArgumentParser(description="Run tests on bringup-bench")
    parser.add_argument("--short", help="Run short tests (~10 mins)", action="store_true")
    parser.add_argument("--long", help="Run long tests(3+ hours)", action="store_true")

    sub_dirs = []
    if parser.parse_args().short:
        sub_dirs += ["test/bringup-bench/" + dir for dir in short_tests]
    elif parser.parse_args().long:
        sub_dirs += ["test/bringup-bench/" + dir for dir in long_tests]
    else:
        parser.print_help()
        exit(0)
    
    build.log_enabled = False
    run_tests(sub_dirs)
