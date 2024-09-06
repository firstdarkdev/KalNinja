import json
import sys
import subprocess
import os
import tkinter
from os import walk
from tkinter import filedialog

outputs = []
output_names = []
no_image = False

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

print("Compiling code...")

def compile(path):
    for (dir_path, dir_names, file_names) in os.walk(path):
        for file in file_names:
            if (file.endswith(".asm")):
                source = path + file
                destination = file

                destination = destination.rstrip(".asm")
                final = destination
                destination += ".prg"

                build_location = "Build/PRGs/" + path + destination

                outputs.append(build_location)
                output_names.append(final)

                subprocess.run([compiler_path, source, "-f", "CBM", "-o", build_location])

code_path = "Code/"
graphics_path = "Graphics/"
maps_path = "Maps/"
sounds_path = "Sounds/"
sprites_path = "Sprites/"

compile(code_path)
compile(graphics_path)
compile(maps_path)
compile(sounds_path)
compile(sprites_path)

if not no_image:
    print("Creating D64 image...")

    subprocess.run([imager_path, "-format", "kalninja,id", "d64", "Build/kalninja.d64"])

    output_index = 0
    while (output_index < len(outputs)):
        subprocess.run([imager_path, "-attach", "Build/kalninja.d64", "-write", outputs[output_index], output_names[output_index]])
        output_index += 1
    
print("Done.")
