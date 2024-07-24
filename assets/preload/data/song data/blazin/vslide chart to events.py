# fard
import json
import os

# change this for different file name :troll:
file = open(os.getcwd() + "/blazin-chart.json")

jsonData = json.load(file)["notes"]

ourOwnDataLol = []

for section in jsonData["hard"]:
    animName = section['k']
    time = section['t']

    eventData = [animName, time, "", ""]

    ourOwnDataLol.append(eventData)

print(ourOwnDataLol)

# yeah memory leaks are bad B)))
file.close()