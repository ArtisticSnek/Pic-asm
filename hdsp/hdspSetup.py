import translatedCharacters as hdsp

string = "TestStr"
ctrlWord = "0b00000000"
images = ["squiggle.png", "amogus.png"]

preCode = [";Code to place before main loop\n",
          "movlb 00h\n",
          f"movlw {len(string)-1}h\n",
          "movwf stringLength\n",
          f"movlw {len(images)-1}h\n",
          "movwf numberOfudc\n",
          f"movlw {ctrlWord}\n",
          "movwf controlRegister\n",
          "call setControlRegister\n",
          "call defineCustomCharacters\n"]
postCode = [";Code to place after main loop\n"]
postCode+=hdsp.createStringTable(string)
for i,v in enumerate(images):
    postCode+=hdsp.createPixelMap(i,v)

postCode.append("udcTable:\n\tlslf WREG\n\tbrw\n")
for i in range(0,len(images)):
    postCode.append(f"\tcall customCharacter{i}\n\treturn\n")
output = preCode+postCode
with open("hdspSetupGenerated.asm", "w") as f:
        f.writelines(output)
        f.close()

 


