import subprocess
import sys
import os
import pathlib
import argparse

import konata

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
log_enabled = True

def print_log(*args):
    global log_count, log_enabled

    if not log_enabled:
        return

    log_count += 1
    print(f"[{log_count}]", *args)

def print_log_stderr(r):

    if not log_enabled:
        return
    
    print(r, end='')


def reset_log_count():
    global log_count
    log_count = 0

def raise_shell_err(p, *args):
    if p.returncode != 0:
        print(f"Error {p.returncode} - {p.stderr.decode("utf-8")}", file=sys.stderr)
        raise Exception(*args)

def shell(*args):
    print_log(*args)
    p = subprocess.run(args, capture_output=True)
    raise_shell_err(p, *args)
    o = p.stdout.decode("utf-8")
    r = p.stderr.decode("utf-8")
    print_log_stderr(r)
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

def create_linker_script(buildir):
    shell("mkdir", "-p", buildir)
    lds = f"{buildir}/linker.lds"
    with open(lds, "w") as f:
        o, _ = shell(RV_CC, "-E", "-P", "-x", "c", "-I.", f"{BSP_DIR}/linker.lds.in")
        f.write(o)
    return lds

def compile_bsp(buildir):
    lds = create_linker_script(buildir)
    return *compile_dir(f"{BSP_DIR}", buildir), lds

#####

def build_project(projectdir, buildir, targetname, *extra_args):
    bsp_srcs, bsp_objs, lds = compile_bsp(f"{buildir}/{projectdir}/bsp")
    srcs, objs = compile_dir(projectdir, f"{buildir}/{projectdir}", *extra_args)
    target = f"{buildir}/{projectdir}/{targetname}"
    rvlink(srcs, bsp_objs + objs, lds, target)

def build_and_run(projectdir, buildir, *extra_args):
    shell("make")
    build_project(projectdir, buildir, "main.elf", *extra_args)
    os.system(f"""
        ./obj_dir/Vrv32_top -e {buildir}/{projectdir}/main.elf
    """)

def build_and_run_log(projectdir, buildir, stdout_file, profiling_file, *extra_args):
    shell("make")
    build_project(projectdir, buildir, "main.elf", *extra_args)
    os.system(f"""
        ./obj_dir/Vrv32_top -e {buildir}/{projectdir}/main.elf --out {stdout_file} --prof {profiling_file}
    """)

def build_and_run_trace(projectdir, buildir, trace_file, trace_kanata, *extra_args):
    shell("make")
    build_project(projectdir, buildir, "main.elf", *extra_args)
    os.system(f"""
        ./obj_dir/Vrv32_top -e {buildir}/{projectdir}/main.elf --trace {trace_file}
    """)
    konata.kanata_format(trace_file, f"{buildir}/{projectdir}/main.elf", trace_kanata)

def build_and_run_bare(projectdir, buildir, trace_file, trace_kanata, *extra_args):
    shell("make")
    lds = create_linker_script(f"{buildir}/{projectdir}")
    srcs, objs = compile_dir(projectdir, f"{buildir}/{projectdir}", *(extra_args + ("-nostdlib",)))
    target = f"{buildir}/{projectdir}/bare.elf"
    rvlink(srcs, objs, lds, target)
    os.system(f"""
        ./obj_dir/Vrv32_top -e {target} --trace {trace_file}
    """)
    konata.kanata_format(trace_file, f"{target}", trace_kanata)

if __name__ == "__main__":
    # Examples
    #build_and_run("examples/cpp_hello_world", "build")
    #build_and_run_log("examples/c_hello_world", "build", "out", "prof")
    build_and_run_trace("examples/c_hello_world", "build", "trace.trace", "trace.kanata")
    #build_and_run_bare("examples/extra/bare", "build", "trace.trace", "trace.kanata")
    pass
