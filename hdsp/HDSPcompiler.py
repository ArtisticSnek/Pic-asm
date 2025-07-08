import translatedCharacters as hsdp

with open("hdspCode.hdsp", "r") as f:
    lines = f.readlines()
    f.close()
    lines = [i.rstrip("\n").lstrip("\t") for i in lines]
    lines = [i.split() for i in lines]

output = []

customCharacters = {}
for command in lines:
    if command[0] == "defChar": #defChar name file
        characterID = len(customCharacters)
        customCharacters[name] = characterID
