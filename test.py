#!python

import os
import build
import shutil
import filecmp
from pathlib import Path

RED = "\033[31m"
GREEN = "\033[32m"

path_testbench = "test/bringup-bench"
path_common = path_testbench + "/common"
path_build = "build/bringup-bench"
common_headers = ["libmin.h", "libtarg.h"]

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
        
#Run all test on bringup-bench
def run_tests():
    num_test = 0
    num_pass = 0
    num_fail = 0
    
    path = Path("test/bringup-bench/")
    #Get the name of all directories that we want to test
    sub_dirs = [str(d) for d in path.iterdir() if (d.is_dir() and str(d) != path_common and 
                str(d) != path_testbench + "/target" and str(d) != path_testbench + "/scripts")]
    for sub_dir in sub_dirs:
        add_common_headers(sub_dir)
        build.run_test_bringup_bench(sub_dir, sub_dir + "/output.out") # Build and run test
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
    run_tests()
    pass