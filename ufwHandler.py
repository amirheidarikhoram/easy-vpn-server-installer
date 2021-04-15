from sys import argv

if len(argv) == 1:
    print("Not enough args passed to script")
    print("UFW config handler for EasyVPN installer, manipulates config file of UFW and makes UFW allow packet forwarding")
    print("Usage\n  python ifwHandler.py UFW_CONFIG_FILE_ADDRESS")
    exit(1)

fileAddress = argv[1]

file = open(fileAddress)
tempfileDataLines = file.readlines()
fileDataLines = []
for line in tempfileDataLines:
    fileDataLines.append(line.split())

file.close()

lastIndex = 0
for ind in range(0, len(fileDataLines)):
    if len(fileDataLines[ind]) > 1 and fileDataLines[ind][1] == "ufw-before-forward": 
        lastIndex = ind

writeData = ""
for index in range(0, len(fileDataLines)):
    writeData += " ".join(fileDataLines[index])
    if index == lastIndex:
        writeData += "\n\n# allow forwarding for trusted network\n\
-A ufw-before-forward -s 10.10.10.0/24 -j ACCEPT\n\
-A ufw-before-forward -d 10.10.10.0/24 -j ACCEPT"
    if index != (len(fileDataLines) - 1):
        writeData += "\n"
        
file = open(fileAddress, "w")
file.write(writeData)