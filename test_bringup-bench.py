#!python

import build

import os
import shutil
import filecmp
import argparse
from pathlib import Path

RED = "\033[31m"
GREEN = "\033[32m"

path_testbench = "test/bringup-bench"
path_common = path_testbench + "/common"
path_target = path_testbench + "/target"
path_build = "build/bringup-bench"
common_headers = ["libmin.h", "libtarg.h"]

# Lists of all tests
short_tests = ["ackermann", "audio-codec", "avl-tree", "banner", "blake2b", "boyer-moore-search", "bubble-sort", "cipher", "dhrystone", "distinctness", "fft-int", "flood-fill", "frac-calc", "fuzzy-match",
               "fy-shuffle", "gcd-list", "graph-tests", "hanoi", "heapsort", "indirect-test", "kadane", "kepler", "knapsack", "knights-tour", "knights-tour", "longdiv", "max-subseq", "mersenne", "minspan", "murmur-hash",
               "pascal", "priority-queue", "qsort-demo", "quaternions", "quine", "rabinkarp-search", "regex-parser", "rle-compress", "shortest-path", "sieve", "simple-grep", "skeleton", "topo-sort", "totient",
               "vectors-3d", "weekday"]
medium_tests = ["bloom-filter", "grad-descent", "k-means", "", "nr-solver", "parrondo", "spirograph", "life", "primal-test"]
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

# Delete the last "num_lines" of a file
def delete_last_lines(file, num_lines):
    with open(file, 'r') as f:
        lines = f.readlines()
    
    # Eliminar las últimas 'num_lineas_a_eliminar' líneas
    lines = lines[:-num_lines]
    
    # Escribir el contenido modificado de vuelta al archivo
    with open(file, 'w') as f:
        f.writelines(lines)

# Check if the output of the test is the expexted 
def check_test(dirname):
    delete_last_lines(dirname + "/output.out", 5)
    archivos_out = [archivo for archivo in os.listdir(dirname) if archivo.endswith(".out")]
    
    if filecmp.cmp(dirname + "/" + archivos_out[0], dirname + "/" + archivos_out[1], shallow=False):
        os.remove(dirname + "/output.out")
        return True
    else:
        return False

# Print statistics of the tests 
def print_results(num_test, num_pass, num_fail):
    if(num_fail != 0):
        print(f"{RED}[" + str(num_fail) + "/" + str(num_test) + "] TEST FAILED")
        print(f"{GREEN}[" + str(num_pass) + "/" + str(num_test) + "] TEST PASSED")
    else:
        print(f"{GREEN}ALL [" + str(num_pass) + "/" + str(num_test) + "] TESTS PASSED")

def add_target_files_to_common():
    for file in os.listdir(path_target):
        if file.endswith(".c") or file.endswith(".h"):
            shutil.copy2(os.path.join(path_target, file), path_common)
        
#Run all test on bringup-bench
def run_tests(sub_dirs):
    add_target_files_to_common()
    num_test = 0
    num_pass = 0
    num_fail = 0
    
    for sub_dir in sub_dirs:
        add_common_headers(sub_dir)
        build.run_test_bringup_bench(sub_dir, sub_dir + "/output.out", "-D", "TARGET_HOST") # Build and run test
        remove_common_headers(sub_dir)
        if(check_test(sub_dir)):
            num_pass += 1
        else:
            num_fail += 1
            print(f"{RED}TEST: " + sub_dir + " FAIL")
            print("CHECK " + sub_dir + "/output.out")
            print("")
        
        num_test += 1
    
    print_results(num_test, num_pass, num_fail)
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run tests on bringup-bench")
    parser.add_argument("--short", help="Run short tests (~ 4mins)", action="store_true")
    parser.add_argument("--medium", help="Run medium tests(30-60 mins)", action="store_true")
    parser.add_argument("--long", help="Run long tests(3+ hours)", action="store_true")

    sub_dirs = []
    if parser.parse_args().short:
        sub_dirs += ["test/bringup-bench/" + dir for dir in short_tests]
    elif parser.parse_args().medium:
        sub_dirs += ["test/bringup-bench/" + dir for dir in medium_tests]
    elif parser.parse_args().long:
        sub_dirs += ["test/bringup-bench/" + dir for dir in long_tests]
    else:
        parser.print_help()
    
    build.log_enabled = False
    run_tests(sub_dirs)
