scripts
=======

Here's where I keep various scripts that I've written and am able to share.  Many of my best scripts, sadly, are stuck being the IP of an employer or client.

* check_prtdiag.conf - This is an extended configuration file for the check_prtdiag NRPE script.  It adds extra hardware types.  Cleared for release by my employer.
* check_pwage.sh - This is a script I developed for tying into NRPE, as well as for parsing collected passwd and shadow files
* check_showenvironment.conf - From memory, I wrote this one to parse the output of `showenvironment` when run on the XSCF interface of a Sun/Oracle M4000.  Cleared for release by my employer.
* chpwd - this is a wrapper script for expect.chpwd
* clamav-rt - I was experimenting with using incrond to trigger some basic realtime scanning with clamav.  Abandoned for now.
* deploysolsudo - This script tries to simplify the deployment of a sudoers file across multiple Solaris hosts.  It caters for different sudo packages and can be extended to cover more (e.g. CSW, SFW etc) and is as paranoid as possible about ensuring that sudo is not broken.  This script has been superseded in my everyday work by an Ansible playbook.  Cleared for release by my employer.
* expect.chpwd - An expect script I developed for updating a user's password across a Linux and Solaris based server fleet.  Caters for AD-authenticated hosts.  This is one of the more complete expect scripts for this task that I'm aware of, it does still have a couple of edge case issues though.
* genlotto - A simple script that uses 'rand' to generate lotto tickets.
* install-shellcheck - This script performs a baseline setup of nginx and php, and downloads and sets up shellcheck and its webui.  Basically, it mostly/entirely automates setting up your own hosted web based version of shellcheck.net.  Shellcheck is brilliant, you should use it.
* llh - A reinterpretation of a tool by the same name from the hpuxtools toolset.  Provides human readable 'ls' for systems that don't have a version of 'ls' with the '-h' option
* lottocheck - Basically I was having fun with 'genlotto' and the 'nzlottoresults' data set.  See: http://www.rawiriblundell.com/?p=1534
* nzlottoresults - The actual first 1546 draws from NZ's Lotto
* rand - I needed to generate a random integer.  This script is me taking that requirement a bit too far.  I have a bit of pride for this one.
* rpm2pkg - I use 'fpm' to generate packages.  Its Solaris support is borked, so as a workaround I found an rpm2pkg script.  I figured I'd generate the rpm from fpm, then use rpm2pkg to convert it.  The script I found was borked too.  I rewrote it in bash and made it better.
* shuffletest-kfy.sh - This is simply a test script for the Knuth Fisher-Yates algorithm.  The goal being to mix a special character into a generated password.  I was investigating potential performance improvements for my password generator.
* shuffletest.sh - A basic algorithm for randomly inserting a special character into a generated password.  As with shuffletest-kfy.sh, this was simply for testing.
* stunnel.init - This is an init script for using stunnel to secure check_mk communications.  Cleared for release by my employer.
