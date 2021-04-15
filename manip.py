from sys import argv

if len(argv) < 4:
    print("Not enough args passed to script")
    print("Replacer for EasyVPN installer, manipulates config files values based on keys and comments")
    print("Usage\n  python replacer.py FILE_ADDRESS KEY NEW_VALUE COMMENT=0")
    exit(1)

fileAddress, key, value = argv[1], argv[2], argv[3]
comment = 1 if len(argv) == 5 and argv[4] == "1" else 0

file = open(fileAddress)
tempfileDataLines = file.readlines()
fileDataLines = []
for line in tempfileDataLines:
    fileDataLines.append(line.split())

file.close()
for itIndex in range(0, len(fileDataLines)):
    commented = False
    keyIndex = 0
    dataLine = fileDataLines[itIndex]

    if comment == 1:
        keyIndex = 1
        commented = True
        if dataLine[0] == "#":
            pass
        else:
            fileDataLines[itIndex] = ["#"] + dataLine
    elif comment == 0:
        keyIndex = 0
        commented = False
        if dataLine[0] == "#":
            fileDataLines[itIndex] = dataLine[1:]
        else:
            pass
    else:
        pass

    if fileDataLines[itIndex][keyIndex] == key:
        if value != "nnpx":
            fileDataLines[itIndex][keyIndex + 2] = value

writeData = ""
for index, line in enumerate(fileDataLines):
    writeData += " ".join(line)
    if index != (len(fileDataLines) - 1):
        writeData += "\n"
        
file = open(fileAddress, "w")
file.write(writeData)