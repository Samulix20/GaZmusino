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
    f"-I{BSP_DIR}",
]

OPT_FLAGS = [
    "-fdata-sections", 
    "-ffunction-sections", 
    "-Wl,--gc-sections,-S",
    "-Wall",
    "-Wextra",
    "-O3",
]

RV_BARE_CXX_FLAGS = [
    "-fno-exceptions", 
    "-fno-unwind-tables",
    "-fno-rtti",
]

RV_CC_FLAGS = OPT_FLAGS + ARCH_FLAGS
RV_CXX_FLAGS = RV_CC_FLAGS + RV_BARE_CXX_FLAGS

####

def remove_all(l, v):
    return [i for i in l if i != v]

####

def raise_shell_err(p, *args):
    if p.returncode != 0:
        print(f"Error {p.returncode} - {p.stderr.decode("utf-8")}", file=sys.stderr)
        raise Exception(*args)

def shell(*args):
    p = subprocess.run(args, capture_output=True)
    raise_shell_err(p, *args)
    return p.stdout.decode("utf-8")

def shell_redir(fpwd, *args):
    with open(fpwd, "w") as f:
        f.write(shell(*args))

#####

def find_srcs(d, *args):
    r = []
    for p in args:
        r += shell("find", d, "-name", p)[:-1].split('\n')
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

def rvlink(srcs, objs, lds, target):
    args = ["-T", lds, *objs, "-o", target]

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
    shell_redir(lds, RV_CC, "-E", "-P", "-x", "c", f"-I{BSP_DIR}", f"{BSP_DIR}/linker.lds.in")
    return *compile_dir(f"{BSP_DIR}", buildir), lds

#####

def compile_and_link_test(testdir, buildir, targetname, *extra_args):
    bsp_srcs, bsp_objs, lds = compile_bsp(f"{buildir}/bsp")
    srcs, objs = compile_dir(testdir, f"{buildir}/{testdir}", *extra_args)
    target = f"{buildir}/{testdir}/{targetname}"
    rvlink(srcs, bsp_objs + objs, lds, target)
    shell_redir(f"{target}.dump", RV_DMP, "-d", target)

def run_test(testdir, logfile, *extra_args):
    compile_and_link_test(testdir, "build", "main.elf", *extra_args)
    os.system(f"""
        ./obj_dir/Vrv32_top -e build/{testdir}/main.elf > {logfile}
    """)

if __name__ == "__main__":
    return

