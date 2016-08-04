# to-do-list-maker
A Perl script that I conceived and wrote as the final project for a class at school in which we were learning Perl



Joseph Santantasio
CIS 280A project
Fall 2015

Program Description: This is a to-do list or schedule maker which allows users to
create a profile and then add and remove tasksby giving them a due date and a
description.  Tasks are assigned a TaskID which is used to uniquely identify each
task (each new task is given an ID which is 1 higher than the highest taskID in the
file) and is used in checking off tasks.  Dates and times are kept track of via the
DateTime module created by Dave Rolsky.  The script will create a directory called
"profiles" in whatever directory it is run in (if the profiles folder already exists
it isn't recreated).  Within the "profiles" directory subdirectories are created for
each new profile.  Each profile folder is created with 2 text files: one holds basic
information about the user such as their profile name and the date and time that
they last ran the script which is used to determine what days the user can add tasks
to (up to a week).  If either file is deleted the script will restore new ones
however task data cannot be restored once deleted.

User interaction: The program interacts with users via a command loop which parses a
few commands which can be viewed with the "help" command.  The script can take 1 or
0 command line arguments, that 1 being the name of a user whose profile will be
loaded or created on startup.  If no name is provided on the command line the script
will prompt the user for a name on startup.

Running: As mentioned, the script (to-do.pl) makes heavy use of the DateTime module
created by Dave Rolsky which must be install from CPAN in order to run the program. 
This is the only external module it uses so afterwards it can simply run.

Steps:
1: Install DateTime module

2: perl to-do.pl (with an optional 1 word argument for a profile name)

3: Follow the on-screen instructions.
