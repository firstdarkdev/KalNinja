import json
import sys
import subprocess
import os
import tkinter
from os import walk
from tkinter import filedialog

no_image = False
disk_links = dict()
compiler_path = "Compiler/C64Ass.exe"
imager_path = ""
arguments_length = len(sys.argv)

argument_index = 0
while argument_index < arguments_length:
    if (sys.argv[argument_index] == "-Compiler"):
        print ("Compiler location overridden to " + sys.argv[argument_index + 1])
        compiler_path = sys.argv[argument_index + 1]
        argument_index += 1

    elif (sys.argv[argument_index] == "-Imager"):
        print ("Disk imager location overridden to " + sys.argv[argument_index + 1])
        imager_path = sys.argv[argument_index + 1]
        argument_index += 1

    elif (sys.argv[argument_index] == "-NoImage"):
        print ("Requested only PRG files, assuming no Imager available.")
        no_image = True

    argument_index += 1

if (compiler_path == ""):
    print("Opening compiler target wizard...")
    compiler_path = tkinter.filedialog.askopenfilename()
    print(compiler_path)

if ((imager_path == "") & (no_image != True)):
    print("Opening imager target wizard...")
    imager_path = tkinter.filedialog.askopenfilename()
    print(imager_path)

print("Compiling libraries...")

def compile_labels(path):
    for (dir_path, dir_names, file_names) in os.walk(path):
        for file in file_names:
            if (file.endswith(".lib.asm")):
                source = dir_path + file
                artifact_name = source.rstrip(".lib.asm") + ".prg"
                target_file_name = source.rstrip(".lib.asm") + ".asm"
                artifact_to_delete = os.getcwd() + "\\" + artifact_name

                subprocess.run([compiler_path, source, "-l", target_file_name, "-o", artifact_name])
                os.remove(artifact_to_delete)

compile_labels("Library\\")

print("Compiling code...")

def compile(path):
    for (dir_path, dir_names, file_names) in os.walk(path):
        files_for_disk = []
        for file in file_names:
            if (file.endswith(".asm")):
                source = dir_path + "/" + file

                destination = file.rstrip(".asm")
                destination += ".prg"

                build_location = "Build/PRGs/" + dir_path.lstrip(path) + "/" + destination

                files_for_disk.append(build_location)

                subprocess.run([compiler_path, source, "-f", "CBM", "-o", build_location])
        if (len(files_for_disk) > 0):
            disk_name = dir_path.rstrip("/")
            disk_links[disk_name.lstrip(path)] = files_for_disk

compile("Code/")

if not no_image:
    print("Creating D64 images...")

    for disk in disk_links:
        print(disk + "...")
        disk_path = "Build/" + disk + ".d64"
        subprocess.run([imager_path, "-format", disk + ",id", "d64", disk_path])

        for file in disk_links[disk]:
            target_file_name = file.split(".")[0]
            subprocess.run([imager_path, "-attach", disk_path, "-write", file, target_file_name.split("/")[-1]])
        
    
print("Done.")
