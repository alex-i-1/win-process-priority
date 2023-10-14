Watch the priority of some processes.

In case if you don't want some of your processes stay with "Normal" priority you'd need a special tool, and here is one.

Powershell + Task Scheduler are used.
Technically it works this way: registers a process creation event with 'Register-CimIndicationEvent', and then waits with 'Wait-Event'.

Even though this tool is simple, since it deals with process priority, it represents a small danger. Read "usage.txt" first, then review the actual scripts, and only then run it.

