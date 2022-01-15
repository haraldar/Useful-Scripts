### Content

---
1. [livehosts.sh](#livehostssh)
2. [wrap2vbs.vbs](#wrap2vbsvbs)

---

#### livehosts.sh

---

#### What is it.

This bash-script is designed to flood a (home) network with different nmap pings and collecting all responding hosts.

#### Why is it.

The thought behind that script is, that as a newbie to nmap I keep getting inconsistencies when trying to get my smartphone to respond. Sometimes it responds, sometimes not, sometimes twice in a row, sometimes not twice in a row, but it most often responds when I keep changing between different pings. Therefore having to run multiple pings anyways, in my safe home environment I can just mass ping different flavors of nmap pings and collect all the hosts that respond.

---

#### wrap2vbs.vbs

---

#### What is it.

The program creates a VBS-file containing wrapped code, that when run creates a runnable and/ or deletable file that contains the unwrapped code.

#### Why is it.

At work I encountered a certain problem, that I had written a lot of code in Batch, but I wanted to switch to VBS for certain reasons. Obviously, because Batch is not VBS, I would have to rewrite and change a lot of BAT-code to pure VBScript-code or make a weird BAT-VBS-hybrid-baby. But since there was not any reason for optimization once I would have a working script, I decided that I could use the features of VBS and Batch, if I simply create a Batch-file from a VBS-file and run and then delete it.
