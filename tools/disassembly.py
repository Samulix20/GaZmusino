import subprocess
import re
import sys

def disassembly(elf_file):
    # run objdump to get disassembly
    r = subprocess.run(
        ["riscv32-unknown-elf-objdump", "-d", elf_file],
        capture_output=True)

    for l in r.stdout.splitlines():
        #  pc:  raw_instr  instr_str  <tag>  #comment
        m = re.search(
            r"^[\s\t]*([0-9a-f]+):[\s\t]*[0-9a-f]+[\s\t]*([^<#]+)[<#]*",
            l.decode("utf-8"))
        if (m):
            # pc;raw_instr;instr
            pc = int(m.groups()[0], base=16)
            instr = m.groups()[1].replace('\t', ' ')
            print(f'{pc};{instr}')

# usage disassembly.py elf_filename
if __name__ == "__main__":
    disassembly(sys.argv[1])
