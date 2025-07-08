charToNum = {
    "Arrow" : 0,
    "¿" : 1,
    "xHi" : 2,
    "NHi" : 3,
    "nHi" : 4,
    "DiPro" : 5,
    "ß" : 6,
    "smalldelta" : 7,
    "bigdelta" : 8,
    "^h" : 9,
    "B8" : 10,
    "lamba" : 11,
    "micro" : 12,
    "pi" : 13,
    "alpha" : 14,
    "Sum" : 15,
    "-t" : 16,
    "theta" : 17,
    "omega" : 18,
    "á" : 19,
    "Á" : 20,
    "Ä" : 21,
    "ä" : 22,
    "Ö" : 23,
    "ö" : 24,
    "Ü" : 25,
    "ü" : 26,
    "right" : 27,
    "sqrt" : 28,
    "sqr" : 29,
    "£" : 30,
    "Yen" : 31,
    " " : 32,
    "!" : 33,
    '"' : 34,
    "#" : 35,
    "$" : 36,
    "%" : 37,
    "&" : 38,
    "'" : 39,
    "(" : 40,
    ")" : 41,
    "*" : 42,
    "+" : 43,
    "," : 44,
    "-" : 45,
    "." : 46,
    "/" : 47,
    "0" : 48,
    "1" : 49,
    "2" : 50,
    "3" : 51,
    "4" : 52,
    "5" : 53,
    "6" : 54,
    "7" : 55,
    "8" : 56,
    "9" : 57,
    ":" : 58,
    ";" : 59,
    "<" : 60,
    "=" : 61,
    ">" : 62,
    "?" : 63,
    "@" : 64,
    "A" : 65,
    "B" : 66,
    "C" : 67,
    "D" : 68,
    "E" : 69,
    "F" : 70,
    "G" : 71,
    "H" : 72,
    "I" : 73,
    "J" : 74,
    "K" : 75,
    "L" : 76,
    "M" : 77,
    "N" : 78,
    "O" : 79,
    "P" : 80,
    "Q" : 81,
    "R" : 82,
    "S" : 83,
    "T" : 84,
    "U" : 85,
    "V" : 86,
    "W" : 87,
    "X" : 88,
    "Y" : 89,
    "Z" : 90,
    "[" : 91,
    "B/" : 92,
    "]" : 93,
    "up" : 94,
    "_" : 95,
    "'1" : 96,
    "a" : 97,
    "b" : 98,
    "c" : 99,
    "d" : 100,
    "e" : 101,
    "f" : 102,
    "g" : 103,
    "h" : 104,
    "i" : 105,
    "j" : 106,
    "k" : 107,
    "l" : 108,
    "m" : 109,
    "n" : 110,
    "o" : 111,
    "p" : 112,
    "q" : 113,
    "r" : 114,
    "s" : 115,
    "t" : 116,
    "u" : 117,
    "v" : 118,
    "w" : 119,
    "x" : 120,
    "y" : 121,
    "z" : 122,
    "{" : 123,
    "}" : 124,
    "~" : 125,
    "pattern" : 126}
def charToBin(character):
    idChar = charToNum[character]
    return (bin(idChar))
def createStringTable(string):
    output = ["string:\n",
              "\tbrw\n"]
    for i in string:
        output.append(f"\tretlw {hex(charToNum[i]).lstrip('0x').upper()+'h'}\n")
    if __name__ == "__main__":
        print(i.rstrip("\n") for i in output)
    return output

from PIL import Image
def createPixelMap(number, imageFile):
    pic = Image.open(imageFile)
    pixels = pic.load()
    output = [f"customCharacter{number}:\n\tmovlb 00h\n\tmovf udcTableIndex, w\n\tbrw\n\tretlw 0{hex(number).lstrip('0x').upper()+'h'}\n"]
    output+=["\tretlw 0b" for i in range(0,7)]
    for y in range(0,7):
        for x in range(0,5):
            if pixels[x,y] == (0,0,0,255):
                output[y+1]+="1"
            else:
                output[y+1]+="0"
        output[y+1]+="\n"
    with open("characterTable.asm", "w") as f:
        f.writelines(output)
        f.close()
    if __name__ == "__main__":
        for i in output:
            print(i.rstrip("\n"))
    return output
    
            

