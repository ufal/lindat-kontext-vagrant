# Vagrant project for LINDAT kontext

This project creates a virtual machine with LINDAT version of the Kontext (see [1]) web interface of Manatee (see [1]).
A bare OS is downloaded, provisioned with basic software by [puppet](https://puppetlabs.com/). Afterwards, 
Kontext and its requirements are installed by a shell script.

The contents of the `projects` directory is shared between your OS and the guest VM created by this project.

## Purpose

In addition to the default vagrant use cases, this project simplifies remote debugging and contains a few additional 
software packages commonly used during debugging.

## How to install

Prerequisites: [Vagrant](https://www.vagrantup.com/), [virtualbox](https://www.virtualbox.org/), (optional) [PyCharm 4.+](https://www.jetbrains.com/pycharm/).

1. clone this project
    ```
        git clone https://github.com/ufal/lindat-kontext-vagrant
    ```

2. get test kontext data
    ```
        cd lindat-kontext-vagrant/projects/config/kontext && git clone https://github.com/ufal/lindat-kontext-ovm data
    ```

3. (optional) copy `pycharm-debug.egg` from Pycharm installation (see [2]) to `projects/debug/`

4. create the VM by executing the following command from lindat-kontext-vagran directory 
    ```
        vagrant up
    ```

5. go to [http://localhost:9999/](http://localhost:9999/) and test [Kontext](http://localhost:9999/kontext/run.cgi/corplist) - 
there should be exactly one available corpora

6. (optional) login to the VM
    ```
        vagrant ssh
    ```

7. (optional) configure remote debug server (see [2]) in PyCharm so that Kontext from the VM can connect to it.
 This means that you should be able to reach your OS from the created VM (see [3]). Finally, 
 add the following python code (change host/port to match your setup) to the place where you would 
 like to start debugging e.g., /opt/lindat/kontext/public/run.cgi
    ```python
        import pydevd
        pydevd.settrace(
            "192.168.2.4", 
            port=11111, 
            suspend=False, 
            stdoutToServer=False, 
            stderrToServer=False, 
            trace_only_current_thread=True, 
            overwrite_prev_trace=False)
    ```
 and add the following to the end of the file otherwise the `run.cgi` will not finish (see [4]) 
 when invoked from apache and the output contents (http contents) will not get to the user.
    ```python
        pydevd.stoptrace()
    ```
 
### Note: You can change the location of the executed kontext script in order to directly work on the same sources.

Change `/etc/apache/sites-enabled/000-default.conf` to point to ` /home/vagrant/projects/libs/current/kontext/public`.
The `projects/libs/current` directory (on your OS) should be a copy of the `/opt/lindat/` directory (on the created VM)
after execution of [projects/setup.kontext.sh](projects/setup.kontext.sh).

### Note: You can set up remote script execution in PyCharm using the Vagrant file directly.
 
However, it will not help with cgi scripts executed by apache.

  
## More details

Vagrant uses [Vagrantfile](Vagrantfile), which reads configuration from [config/default.yaml](config/default.yaml), 
puppet prerequisites are installed by [puppet-librarian](https://github.com/rodjek/librarian-puppet) using 
[projects/Puppetfile](projects/Puppetfile), puppet uses [projects/puppet-setup.pp](projects/puppet-setup.pp) to install basic software including
[phpmyadmin](http://www.phpmyadmin.net/) and [munin](http://munin-monitoring.org/) which can help during debugging.
Afterwards, munin is configured using [projects/setup.munin.sh](projects/setup.munin.sh).

Finally, kontext is installed by [projects/setup.kontext.sh](projects/setup.kontext.sh).

Configuration files are in [projects/config](projects/config), web directory contents in [projects/www](projects/www). 


# References

[1] [Kontext](https://bitbucket.org/ucnk/kontext) is a fork of [Bonito](http://nlp.fi.muni.cz/trac/noske) 2.68 
to the corpus management tool [Manatee](http://nlp.fi.muni.cz/trac/noske).

[2] See https://www.jetbrains.com/pycharm/help/remote-debugging.html

[3] Log in to the create VM and test connection to your OS using e.g., telnet (ping is not enough)

[4] Simply put, debugging threads are not correctly terminated.