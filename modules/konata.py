import csv

def in_pipeline(pc, pipeline):
    for stage in ["W", "M", "E", "D", "F"]:
        if stage in pipeline and not pipeline[stage][2] and pipeline[stage][0] == pc:
            pipeline[stage][2] = True
            return True, stage
    return False, '-'

stage_to_num = {
    "W": 5, "M": 4, "E": 3, "D": 2, "F": 1
}

next_id = 0
def gen_id():
    global next_id
    next_id += 1
    return next_id

import subprocess
import re

INSTR_REGEX = r"^[\s\t]*([0-9a-f]+):[\s\t]*[0-9a-f]+[\s\t]*([^<#]+)#*(.*)"

def run_objdump(elf_file):
    r = subprocess.run(
        ["riscv64-unknown-elf-objdump", "-d", elf_file],
        check=False,
        capture_output=True
    )
    s = {}
    for l in r.stdout.splitlines():
        l = l.decode("utf-8")
        m = re.search(INSTR_REGEX, l)
        if m:
            pc = int(m.groups()[0], base=16)
            instr = m.groups()[1].replace('\t', ' ').rstrip()
            comment = m.groups()[2].strip()
            if comment != "":
                comment = "# " + comment
            s[pc] = f"{instr} {comment}"
    return s

def kanata_format(trace_path, elf_path, out_path):
    instr_dict = run_objdump(elf_path)
    
    out_f = open(out_path, "w")

    with open(trace_path, "r") as f:
        reader = csv.reader(f, delimiter=';')

        tracked_instructions = {}
        pipeline = {}

        # Kanata format output
        out_f.write("Kanata\t0004\n")
        out_f.write("C=\t0\n")

        while (True):
            i = 0

            # Create pipeline structure
            pipeline = {}
            for r in reader:
                if i == 0:
                    cycle_id = int(r[1])
                elif i > 0:
                    stage = r[0]
                    if i == 1:
                        pipeline[stage] = r[1:3] + ['X', False]
                    elif r[3] == '0':
                        pipeline[stage] = r[1:3] + [False]
                    elif stage in pipeline:
                        pipeline.pop(stage)
                i += 1
                if i == 6:
                    break

            # Log file has ended, exit
            if i == 0:
                break

            out_f.write("C\t1\n")

            # Delay delete to iterate over keys
            to_delete = []
            # Keys are iterated in ascending order
            for tracked_id in tracked_instructions.keys():
                # Find if instruction is in pipeline, starting from W -> F
                present, stage = in_pipeline(tracked_instructions[tracked_id][0], pipeline)
                if not present:
                    to_delete.append(tracked_id)
                    t = 1 if tracked_instructions[tracked_id][1] != 'W' else 0
                    out_f.write(f"R\t{tracked_id}\t0\t{t}\n")
                else:
                    # If instruction is in posterior stage update status
                    if stage_to_num[stage] > stage_to_num[tracked_instructions[tracked_id][1]]:
                        tracked_instructions[tracked_id][1] = stage
                        out_f.write(f"S\t{tracked_id}\t0\t{stage}\n")

                    # If is previous, it has reentered after exiting 
                    # Remove, it will be added in the next section
                    elif stage_to_num[stage] < stage_to_num[tracked_instructions[tracked_id][1]]:
                        to_delete.append(tracked_id)
                        t = 1 if tracked_instructions[tracked_id][1] != 'W' else 0
                        out_f.write(f"R\t{tracked_id}\t0\t{t}\n")

            # Actual delete from track
            for tracked_id in to_delete:
                tracked_instructions.pop(tracked_id)

            # Check if a new instruction should be added or is the same one stuck at F
            register_new = True
            for tracked_id in tracked_instructions.keys():
                if tracked_instructions[tracked_id][0] == pipeline['F'][0] and tracked_instructions[tracked_id][1] == 'F':
                    register_new = False
            if register_new:
                new_id = gen_id()
                tracked_instructions[new_id] = [pipeline['F'][0], 'F']
                out_f.write(f"I\t{new_id}\t0\t0\n")
                out_f.write(f"S\t{new_id}\t0\tF\n")
                out_f.write(f"L\t{new_id}\t0\t{instr_dict[int(pipeline['F'][0])]}\n")
    
    out_f.close()