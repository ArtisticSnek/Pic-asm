from PIL import Image
with open("config.cfg","r") as f:
    file = f.read()
    f.close()

pic = Image.open(file)
pixels = pic.load()
output = ["imagePixelMap:\n","brw\n"]
for x in range(0,8):
    for y in range(0,8):
        if pixels[y,x] == (0,0,0,255):
            output.append(f"retlw {x}{y}h\n")
output.append(f"retlw 0FFh\n")
with open("lookupTable.asm", "w") as f:
    f.writelines(output)
    f.close()
for i in output:
    print(i)
