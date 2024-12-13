#!python

import subprocess
import sys

import os
import pathlib


RV_CROSS = "riscv64-unknown-elf-"
RV_CC = f"{RV_CROSS}gcc"
RV_CXX = f"{RV_CROSS}g++"
RV_DMP = f"{RV_CROSS}objdump"

BSP_DIR = "bsp"

ARCH_FLAGS = [
    "-march=rv32i_zmmul_zicsr",
    "-mabi=ilp32",
]

INCLUDE_FLAGS = [
    f"-I{BSP_DIR}",
    "-I."
]

OPT_FLAGS = [
    "-fdata-sections", 
    "-ffunction-sections", 
    "-Wl,--gc-sections,-S",
    "-Wall",
    "-Wextra",
    "-O3",
    "-DTARGET_HOST",
]

RV_BARE_CXX_FLAGS = [
    "-fno-exceptions", 
    "-fno-unwind-tables",
    "-fno-rtti",
]

RV_CC_FLAGS = OPT_FLAGS + ARCH_FLAGS + INCLUDE_FLAGS
RV_CXX_FLAGS = RV_CC_FLAGS + RV_BARE_CXX_FLAGS

path_common = "test/bringup-bench/common"

####

def remove_all(l, v):
    return [i for i in l if i != v]

####

log_count = 0
def print_log(r, *args):
    global log_count
    log_count += 1
    print(f"[{log_count}]", *args)
    print(r, end='')

def reset_log_count():
    global log_count
    log_count = 0

def raise_shell_err(p, *args):
    if p.returncode != 0:
        print(f"Error {p.returncode} - {p.stderr.decode("utf-8")}", file=sys.stderr)
        raise Exception(*args)

def shell(*args):
    p = subprocess.run(args, capture_output=True)
    raise_shell_err(p, *args)
    o = p.stdout.decode("utf-8")
    r = p.stderr.decode("utf-8")
    print_log(r, *args)
    return o, r

#####

def find_srcs(d, *args):
    r = []
    for p in args:
        r += shell("find", d, "-name", p)[0][:-1].split('\n')
    return remove_all(r, "")

def src_is_cpp(src):
    return pathlib.Path(src).suffix in [".cpp", "cc"]

def srcs_are_cpp(srcs):
    for src in srcs:
        if src_is_cpp(src):
            return True
    return False

#####

def rvcomp(src, buildir, *extra_args):
    obj = f"{buildir}/{pathlib.Path(src).stem}.o"
    args = [*extra_args, "-c", src, "-o", obj]

    if src_is_cpp(src):
        shell(RV_CXX, *RV_CXX_FLAGS, *args)
    else:
        shell(RV_CC, *RV_CC_FLAGS, *args)
    return obj

def rvlink(srcs, objs, lds, target, *extra_args):
    args = [*extra_args, "-T", lds, *objs, "-o", target]

    if srcs_are_cpp(srcs):
        shell(RV_CXX, *RV_CXX_FLAGS, *args)
    else:
        shell(RV_CC, *RV_CC_FLAGS, *args)
    return target

#####

def compile_dir(d, buildir, *extra_args):
    shell("mkdir", "-p", buildir)
    srcs = find_srcs(d, "*.S", "*.c", "*.cpp")
    objs = [rvcomp(src, buildir, *extra_args) for src in srcs]
    return srcs, objs

def compile_bsp(buildir):
    shell("mkdir", "-p", buildir)
    lds = f"{buildir}/linker.lds"
    with open(lds, "w") as f:
        o, _ = shell(RV_CC, "-E", "-P", "-x", "c", "-I.", f"{BSP_DIR}/linker.lds.in")
        f.write(o)
    return *compile_dir(f"{BSP_DIR}", buildir), lds

#####

def build_project(projectdir, buildir, targetname, *extra_args):
    bsp_srcs, bsp_objs, lds = compile_bsp(f"{buildir}/{projectdir}/bsp")
    srcs, objs = compile_dir(projectdir, f"{buildir}/{projectdir}", *extra_args)
    target = f"{buildir}/{projectdir}/{targetname}"
    rvlink(srcs, bsp_objs + objs, lds, target)

# TODO implement function that takes a list of source files instead of a directory
# and produces an executable file
def build_srcs(srcs, buildir, targetname, *extra_args):
    return

##### TODO move these to test.py

def compile_and_link_test_bringup_bench(testdir, buildir, targetname, *extra_args):
    bsp_srcs, bsp_objs, lds = compile_bsp(f"{buildir}/{testdir}/bsp")
    common_srcs, common_objs = compile_dir(path_common,f"{buildir}/{testdir}/common")
    srcs, objs = compile_dir(testdir, f"{buildir}/{testdir}", *extra_args)
    target = f"{buildir}/{testdir}/{targetname}"
    rvlink(srcs, bsp_objs + objs + common_objs, lds, target)

def compile_and_link_test(testdir, buildir, targetname, *extra_args):
    bsp_srcs, bsp_objs, lds = compile_bsp(f"{buildir}/{testdir}/bsp")
    srcs, objs = compile_dir(testdir, f"{buildir}/{testdir}", *extra_args)
    target = f"{buildir}/{testdir}/{targetname}"
    rvlink(srcs, bsp_objs + objs, lds, target)

def run_test_bringup_bench(testdir, logfile, *extra_args):
    compile_and_link_test_bringup_bench(testdir, "build", "main.elf", *extra_args)
    os.system(f"""
        ./obj_dir/Vrv32_top -e build/{testdir}/main.elf > {logfile}
    """)

def run_test_log(testdir, stdout_file, profiling_file, *extra_args):
    compile_and_link_test(testdir, "build", "main.elf", *extra_args)
    os.system(f"""
        ./obj_dir/Vrv32_top -e build/{testdir}/main.elf --out {stdout_file} --prof {profiling_file}
    """)

def run_test(testdir, *extra_args):
    compile_and_link_test(testdir, "build", "main.elf", *extra_args)
    os.system(f"""
        ./obj_dir/Vrv32_top -e build/{testdir}/main.elf
    """)

if __name__ == "__main__":
    run_test_log("test/c_tests/hello", "stdout.txt", "prof.yaml")
    # TODO setup argument parse
    # --elf target file name, default main.elf
    # --objs object files to link, default []
    # --srcs list of files to compile, default []
    # --proj directory from which extract files, default null
    # --bdir build directory, default build

