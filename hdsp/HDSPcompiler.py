import translatedCharacters as hsdp

with open("hdspCode.hdsp", "r") as f:
    lines = f.readlines()
    f.close()
    lines = [i.rstrip("\n").lstrip("\t") for i in lines]
    lines = [i.split() for i in lines]

output = []

class program:
    def __init__(self):
        self.preCode = []
        self.postCode = []
        self.udc = {}
        self.images = []

script = program()

def createCustomCharacter(name, index, file, scriptObj):
    scriptObj.udc[name] = index
    scriptObj.append(file)
    

customCharacters = {}
for command in lines:
    if command[0] == "defChar": #defChar name index file
        createCustomCharacter(command[1], command[2], command[3], script)
        
        
