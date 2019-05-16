#!/usr/bin/python3
import subprocess

res = subprocess.run(["bin/squeue", "--state=pd", "--Format=reason",
    "--noheader"], stdout=subprocess.PIPE)
#print("res=\n{0}\n".format(res))

string = (str(res.stdout.decode("utf-8")))
#print("string=\n{0}".format(string))

words = string.split()
#print("words=\n{0}\n".format(words))

rc = 0
for word in words:
    #print(word)
    if word != "JobHeldAdmin" and word != "JobHeldUser":
        print("fail for word {0}".format(word))
        rc = rc + 1

print("Exiting with rc {0}".format(rc))
exit(rc)
