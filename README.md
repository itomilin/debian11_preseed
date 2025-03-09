Change the environment variables in the **generate_preseed.sh** file and generate a preseed file for yourself.

!!Check makefile!!


https://wiki.debian.org/DebianInstaller/Preseed

# Loading the preseeding file from a webserver
![alt text](image1.png)
When the graphical installer boot menu appears, PRESS the "Help" entry
Press F8
![alt text](image2.png)
The file must be presented as lines on a public web server. (auto url=<your_url>) for example:
![alt text](image3.png)
auto url=https://raw.githubusercontent.com/itomilin/debian_preseed/refs/heads/main/preseeds/worker1-kvm

# TODO: pack preseed to iso
https://wiki.debian.org/DebianInstaller/Preseed/EditIso