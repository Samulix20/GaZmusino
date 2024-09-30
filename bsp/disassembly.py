import subprocess
import re
import sys
import os

# Custom instructions (reserved for custom extensions)
RV_CUSTOM_0   = 0b0001011 
RV_CUSTOM_1   = 0b0101011
RV_CUSTOM_2   = 0b1011011
RV_CUSTOM_3   = 0b1111011

RV_ABI_REGISTER_NAMES = {
    0: "zero",   # Hard-wired zero
    1: "ra",     # Return address
    2: "sp",     # Stack pointer
    3: "gp",     # Global pointer
    4: "tp",     # Thread pointer
    5: "t0",     # Temporary register 0
    6: "t1",     # Temporary register 1
    7: "t2",     # Temporary register 2
    8: "s0",     # Saved register/frame pointer
    9: "s1",     # Saved register 1
    10: "a0",    # Function argument/return value 0
    11: "a1",    # Function argument/return value 1
    12: "a2",    # Function argument 2
    13: "a3",    # Function argument 3
    14: "a4",    # Function argument 4
    15: "a5",    # Function argument 5
    16: "a6",    # Function argument 6
    17: "a7",    # Function argument 7
    18: "s2",    # Saved register 2
    19: "s3",    # Saved register 3
    20: "s4",    # Saved register 4
    21: "s5",    # Saved register 5
    22: "s6",    # Saved register 6
    23: "s7",    # Saved register 7
    24: "s8",    # Saved register 8
    25: "s9",    # Saved register 9
    26: "s10",   # Saved register 10
    27: "s11",   # Saved register 11
    28: "t3",    # Temporary register 3
    29: "t4",    # Temporary register 4
    30: "t5",    # Temporary register 5
    31: "t6"     # Temporary register 6
}

def get_bits(value, start, nbits):
    mask = ((1 << (nbits + 1)) - 1) >> 1
    return (value >> start) & mask

def print_instr_fields(instr):
    for k, v in vars(instr).items():
        print(f"\"{k}\": {v}, ", end="")
    print()

class RV_register:
    def __init__(self, v: int):
        self.v = v

    def __str__(self):
        return f"{RV_ABI_REGISTER_NAMES[self.v]}"

class RV_r4_instr:
    
    def __init__(self, instr: int):
        self.opcode = get_bits(instr, 0, 7)
        self.rd = RV_register(get_bits(instr, 7, 5))
        self.func3 = get_bits(instr, 12, 3)
        self.rs1 = RV_register(get_bits(instr, 15, 5))
        self.rs2 = RV_register(get_bits(instr, 20, 5))
        self.func2 = get_bits(instr, 25, 2)
        self.rs3 = RV_register(get_bits(instr, 27, 5))

    def print(self):
        print_instr_fields(self)

class RV_r_instr:

    def __init__(self, instr: int):
        self.opcode = get_bits(instr, 0, 7)
        self.rd = RV_register(get_bits(instr, 7, 5))
        self.func3 = get_bits(instr, 12, 3)
        self.rs1 = RV_register(get_bits(instr, 15, 5))
        self.rs2 = RV_register(get_bits(instr, 20, 5))
        self.func7 = get_bits(instr, 25, 7)
    
    def print(self):
        print_instr_fields(self)


def run_objdump(elf_file):
    return subprocess.run(
        ["riscv64-unknown-elf-objdump", "-d", elf_file],
        check=False,
        capture_output=True
    )

def genum(instr: int) -> tuple[bool, str]:
    d = RV_r_instr(instr)
    if d.opcode == RV_CUSTOM_0:
        return True, f"genum\t{d.rd}"
    return False, ""

def fxmadd(instr: int) -> tuple[bool, str]:
    d = RV_r4_instr(instr)
    if d.opcode == RV_CUSTOM_1:
        return True, f"fxmadd\t{d.rd}, {d.rs1}, {d.rs2}, {d.rs3}, {d.func3}"
    return False, ""

def fxmadd_dsample(instr: int) -> tuple[bool, str]:
    d = RV_r4_instr(instr)
    if d.opcode == RV_CUSTOM_2:
        if d.func2 == 1:
                return True, f"dsample\t{d.rd}, {d.rs2}, {d.rs3}, {d.func3}"
        else:
                return True, f"fxmadd\t{d.rd}, {d.rs1}, {d.rs2}, {d.rs3}, {d.func3}"
    return False, ""

CUSTOM_INSTRUCTION_DECODERS = [
    genum,
    fxmadd,
    fxmadd_dsample
]

INSTR_REGEX = r"^[\s\t]*([0-9a-f]+):[\s\t]*[0-9a-f]+[\s\t]*([^<#]+)[<#]*"
CUSTOM_INSN_REGEX = r"^([\s\t]*[0-9a-f]+:[\s\t]*[0-9a-f]+[\s\t]*)(\.insn\t4, )([^<#]+)[<#]*"

def disassembly_custom(elf_file) -> str:
    s = ""
    r = run_objdump(elf_file)
    for l in r.stdout.splitlines():
        l = l.decode("utf-8")
        # Check for special .insn instructions
        m = re.search(CUSTOM_INSN_REGEX, l)
        if m:
            prefix = m.groups()[0]
            raw_instr = int(m.groups()[2], 16)

            for decoder in CUSTOM_INSTRUCTION_DECODERS:
                m, instr = decoder(raw_instr)
                if m:
                    s += f"{prefix}{instr}\n"
                    break
            # Print .insn version if could not decode
            if not m:
                s += l + '\n'

        else:
            s += l  + '\n'
    return s

def disassembly_csv(text: str):
    s = ""
    for l in text.splitlines():
        #  pc:  raw_instr  instr_str  <tag>  #comment
        m = re.search(INSTR_REGEX, l)
        if m:
            # pc;raw_instr;instr
            pc = int(m.groups()[0], base=16)
            instr = m.groups()[1].replace('\t', ' ')
            s += f'{pc};{instr}\n'
    return s

# usage disassembly.py elf_filename
if __name__ == "__main__":
    elf_file = sys.argv[1]
    dump = disassembly_custom(sys.argv[1])
    csv = disassembly_csv(dump)
    
    dirname = os.path.dirname(elf_file)
    basename = os.path.basename(elf_file)

    with open(f"{elf_file}.dump", "w") as f:
        f.write(dump)
    with open(f"{elf_file}.dump.csv", "w") as f:
        f.write(csv)
