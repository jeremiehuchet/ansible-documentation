Advanced Playbooks
==================

.. image:: http://ansible.cc/docs/_static/ansible_fest_2013.png
   :alt: ansiblefest 2013
   :target: http://ansibleworks.com/fest


Here are some advanced features of the playbooks language.  Using all of these features
are not neccessary, but many of them will prove useful.  If a feature doesn't seem immediately
relevant, feel free to skip it.  For many people, the features documented in `playbooks` will
be 90% or more of what they use in Ansible.

.. contents::
   :depth: 2
   :backlinks: top

Tags
````

.. versionadded:: 0.6

If you have a large playbook it may become useful to be able to run a
specific part of the configuration.  Both plays and tasks support a
"tags:" attribute for this reason.

Example::

    tasks:

        - action: yum name=$item state=installed
          with_items:
             - httpd
             - memcached
          tags:
             - packages

        - action: template src=templates/src.j2 dest=/etc/foo.conf
          tags:
             - configuration

If you wanted to just run the "configuration" and "packages" part of a very long playbook, you could do this::

    ansible-playbook example.yml --tags "configuration,packages"

Playbooks Including Playbooks
`````````````````````````````

.. versionadded:: 0.6

To further advance the concept of include files, playbook files can
include other playbook files.  Suppose you define the behavior of all
your webservers in "webservers.yml" and all your database servers in
"dbservers.yml".  You can create a "site.yml" that would reconfigure
all of your systems like this::

    ----
    - include: playbooks/webservers.yml
    - include: playbooks/dbservers.yml

This concept works great with tags to rapidly select exactly what plays you want to run, and exactly
what parts of those plays.

Ignoring Failed Commands
````````````````````````

.. versionadded:: 0.6

Generally playbooks will stop executing any more steps on a host that
has a failure.  Sometimes, though, you want to continue on.  To do so,
write a task that looks like this::

    - name: this will not be counted as a failure
      action: command /bin/false
      ignore_errors: yes

Accessing Complex Variable Data
```````````````````````````````

Some provided facts, like networking information, are made available as nested data structures.  To access
them a simple '$foo' is not sufficient, but it is still easy to do.   Here's how we get an IP address::

    ${ansible_eth0.ipv4.address}

It is also possible to access variables whose elements are arrays::

    ${somelist[0]}

And the array and hash reference syntaxes can be mixed.

In templates, the simple access form still holds, but they can also be accessed from Jinja2 in more Python-native ways if
that is preferred::

    {{ ansible_eth0["ipv4"]["address"] }}

Magic Variables, and How To Access Information About Other Hosts
````````````````````````````````````````````````````````````````

Even if you didn't define them yourself, ansible provides a few variables for you, automatically.
The most important of these are 'hostvars', 'group_names', and 'groups'.

Hostvars lets you ask about the variables of another host, including facts that have been gathered
about that host.  If, at this point, you haven't talked to that host yet in any play in the playbook
or set of playbooks, you can get at the variables, but you will not be able to see the facts.

If your database server wants to use the value of a 'fact' from another node, or an inventory variable
assigned to another node, it's easy to do so within a template or even an action line::

    ${hostvars.hostname.factname}

Note in playbooks if your hostname contains a dash or periods in it, escape it like so::

    ${hostvars.{test.example.com}.ansible_distribution}

In Jinja2 templates, this can also be expressed as::

    {{ hostvars['test.example.com']['ansible_distribution'] }}

Additionally, *group_names* is a list (array) of all the groups the current host is in.  This can be used in templates using Jinja2 syntax to make template source files that vary based on the group membership (or role) of the host::

   {% if 'webserver' in group_names %}
      # some part of a configuration file that only applies to webservers
   {% endif %}

*groups* is a list of all the groups (and hosts) in the inventory.  This can be used to enumerate all hosts within a group.
For example::

   {% for host in groups['app_servers'] %}
      # something that applies to all app servers.
   {% endfor %}

A frequently used idiom is walking a group to find all IP addresses in that group::

   {% for host in groups['app_servers'] %}
      {{ hostvars[host]['ansible_eth0']['ipv4']['address'] }}
   {% endfor %}

An example of this could include pointing a frontend proxy server to all of the app servers, setting up the correct firewall rules between servers, etc.

Just a few other 'magic' variables are available...  There aren't many.

Additionally, *inventory_hostname* is the name of the hostname as configured in Ansible's inventory host file.  This can
be useful for when you don't want to rely on the discovered hostname `ansible_hostname` or for other mysterious
reasons.  If you have a long FQDN, *inventory_hostname_short* also contains the part up to the first
period, without the rest of the domain.

Don't worry about any of this unless you think you need it.  You'll know when you do.

Also available, *inventory_dir* is the pathname of the directory holding Ansible's inventory host file.

Variable File Separation
````````````````````````

It's a great idea to keep your playbooks under source control, but
you may wish to make the playbook source public while keeping certain
important variables private.  Similarly, sometimes you may just
want to keep certain information in different files, away from
the main playbook.

You can do this by using an external variables file, or files, just like this::

    ---
    - hosts: all
      user: root
      vars:
        favcolor: blue
      vars_files:
        - /vars/external_vars.yml
      tasks:
      - name: this is just a placeholder
        action: command /bin/echo foo

This removes the risk of sharing sensitive data with others when
sharing your playbook source with them.

The contents of each variables file is a simple YAML dictionary, like this::

    ---
    # in the above example, this would be vars/external_vars.yml
    somevar: somevalue
    password: magic

.. note::
   It's also possible to keep per-host and per-group variables in very
   similar files, this is covered in :ref:`patterns`.

Prompting For Sensitive Data
````````````````````````````

You may wish to prompt the user for certain input, and can
do so with the similarly named 'vars_prompt' section.  This has uses
beyond security, for instance, you may use the same playbook for all
software releases and would prompt for a particular release version
in a push-script::

    ---
    - hosts: all
      user: root
      vars:
        from: "camelot"
      vars_prompt:
        name: "what is your name?"
        quest: "what is your quest?"
        favcolor: "what is your favorite color?"

There are full examples of both of these items in the github examples/playbooks directory.

An alternative form of vars_prompt allows for hiding input from the user, and may later support
some other options, but otherwise works equivalently::

   vars_prompt:
     - name: "some_password"
       prompt: "Enter password"
       private: yes
     - name: "release_version"
       prompt: "Product release version"
       private: no

If `Passlib <http://pythonhosted.org/passlib/>`_ is installed, vars_prompt can also crypt the
entered value so you can use it, for instance, with the user module to define a password::

   vars_prompt:
     - name: "my_password2"
       prompt: "Enter password2"
       private: yes
       encrypt: "md5_crypt"
       confirm: yes
       salt_size: 7

You can use any crypt scheme supported by 'Passlib':

- *des_crypt* - DES Crypt
- *bsdi_crypt* - BSDi Crypt
- *bigcrypt* - BigCrypt
- *crypt16* - Crypt16
- *md5_crypt* - MD5 Crypt
- *bcrypt* - BCrypt
- *sha1_crypt* - SHA-1 Crypt
- *sun_md5_crypt* - Sun MD5 Crypt
- *sha256_crypt* - SHA-256 Crypt
- *sha512_crypt* - SHA-512 Crypt
- *apr_md5_crypt* - Apache’s MD5-Crypt variant
- *phpass* - PHPass’ Portable Hash
- *pbkdf2_digest* - Generic PBKDF2 Hashes
- *cta_pbkdf2_sha1* - Cryptacular’s PBKDF2 hash
- *dlitz_pbkdf2_sha1* - Dwayne Litzenberger’s PBKDF2 hash
- *scram* - SCRAM Hash
- *bsd_nthash* - FreeBSD’s MCF-compatible nthash encoding

However, the only parameters accepted are 'salt' or 'salt_size'. You can use you own salt using
'salt', or have one generated automatically using 'salt_size'. If nothing is specified, a salt
of size 8 will be generated.

Passing Variables On The Command Line
`````````````````````````````````````

In addition to `vars_prompt` and `vars_files`, it is possible to send variables over
the ansible command line.  This is particularly useful when writing a generic release playbook
where you may want to pass in the version of the application to deploy::

    ansible-playbook release.yml --extra-vars "version=1.23.45 other_variable=foo"

This is useful, for, among other things, setting the hosts group or the user for the playbook.

Example::

    -----
    - user: $user
      hosts: $hosts
      tasks:
         - ...

    ansible-playbook release.yml --extra-vars "hosts=vipers user=starbuck"

Conditional Execution
`````````````````````

Sometimes you will want to skip a particular step on a particular host.  This could be something
as simple as not installing a certain package if the operating system is a particular version,
or it could be something like performing some cleanup steps if a filesystem is getting full.

This is easy to do in Ansible, with the `only_if` clause, which actually is a Python expression.
Don't panic -- it's actually pretty simple::

    vars:
      favcolor: blue
      is_favcolor_blue: "'$favcolor' == 'blue'"
      is_centos: "'$facter_operatingsystem' == 'CentOS'"

    tasks:
      - name: "shutdown if my favorite color is blue"
        action: command /sbin/shutdown -t now
        only_if: '$is_favcolor_blue'

Variables from tools like `facter` and `ohai` can be used here, if installed, or you can
use variables that bubble up from ansible, which many are provided by the :ref:`setup` module.   As a reminder,
these variables are prefixed, so it's `$facter_operatingsystem`, not `$operatingsystem`.  Ansible's
built in variables are prefixed with `ansible_`.

The only_if expression is actually a tiny small bit of Python, so be sure to quote variables and make something
that evaluates to `True` or `False`.  It is a good idea to use 'vars_files' instead of 'vars' to define
all of your conditional expressions in a way that makes them very easy to reuse between plays
and playbooks.

You cannot use live checks here, like 'os.path.exists', so don't try.

It's also easy to provide your own facts if you want, which is covered in :doc:`moduledev`.  To run them, just
make a call to your own custom fact gathering module at the top of your list of tasks, and variables returned
there will be accessible to future tasks::

    tasks:
        - name: gather site specific fact data
          action: site_facts
        - action: command echo ${my_custom_fact_can_be_used_now}

One common useful trick with only_if is to key off the changed result of a last command.  As an example::

    tasks:
        - action: template src=/templates/foo.j2 dest=/etc/foo.conf
          register: last_result
        - action: command echo 'the file has changed'
          only_if: '${last_result.changed}'

$last_result is a variable set by the register directive. This assumes Ansible 0.8 and later.

In Ansible 0.8, a few shortcuts are available for testing whether a variable is defined or not::

    tasks:
        - action: command echo hi
          only_if: is_set('$some_variable')

There is a matching 'is_unset' that works the same way.  Quoting the variable inside the function is mandatory.

When combining `only_if` with `with_items`, be aware that the `only_if` statement is processed separately for each item.
This is by design::

    tasks:
        - action: command echo $item
          with_item: [ 0, 2, 4, 6, 8, 10 ]
          only_if: "$item > 5"

While `only_if` is a pretty good option for advanced users, it exposes more guts than we'd like, and
we can do better.  In 1.0, we added 'when', which is like syntactic sugar for `only_if` and hides
this level of complexity.  See more on this below.

Conditional Execution (Simplified)
``````````````````````````````````

.. versionadded: 0.8

In Ansible 0.9, we realized that only_if was a bit syntactically complicated, and exposed too much Python
to the user.  As a result, the 'when' set of keywords was added.  The 'when' statements do not have
to be quoted or casted to specify types, but you should separate any variables used with whitespace.  In
most cases users will be able to use 'when', but for more complex cases, only_if may still be required.

Here are various examples of 'when' in use.  'when' is incompatible with 'only_if' in the same task::

    - name: "do this if my favcolor is blue, and my dog is named fido"
      action: shell /bin/false
      when_string: $favcolor == 'blue' and $dog == 'fido'

    - name: "do this if my favcolor is not blue, and my dog is named fido"
      action: shell /bin/true
      when_string: $favcolor != 'blue' and $dog == 'fido'

    - name: "do this if my SSN is over 9000"
      action: shell /bin/true
      when_integer: $ssn > 9000

    - name: "do this if I have one of these SSNs"
      action: shell /bin/true
      when_integer:  $ssn in [ 8675309, 8675310, 8675311 ]

    - name: "do this if a variable named hippo is NOT defined"
      action: shell /bin/true
      when_unset: $hippo

    - name: "do this if a variable named hippo is defined"
      action: shell /bin/true
      when_set: $hippo

    - name: "do this if a variable named hippo is true"
      action: shell /bin/true
      when_boolean: $hippo

The when_boolean check will look for variables that look to be true as well, such as the string 'True' or
'true', non-zero numbers, and so on.

.. versionadded: 1.0

In 1.0, we also added when_changed and when_failed so users can execute tasks based on the status of previously
registered tasks.  As an example::

    - name: "register a task that might fail"
      action: shell /bin/false
      register: result
      ignore_errors: True

    - name: "do this if the registered task failed"
      action: shell /bin/true
      when_failed: $result

    - name: "register a task that might change"
      action: yum pkg=httpd state=latest
      register: result

    - name: "do this if the registered task changed"
      action: shell /bin/true
      when_changed: $result

Note that if you have several tasks that all share the same conditional statement, you can affix the conditional
to a task include statement as below.  Note this does not work with playbook includes, just task includes.  All the tasks
get evaluated, but the conditional is applied to each and every task::

    - include: tasks/sometasks.yml
      when_string: "'reticulating splines' in $output"

Conditional Imports
```````````````````

Sometimes you will want to do certain things differently in a playbook based on certain criteria.
Having one playbook that works on multiple platforms and OS versions is a good example.

As an example, the name of the Apache package may be different between CentOS and Debian,
but it is easily handled with a minimum of syntax in an Ansible Playbook::

    ---
    - hosts: all
      user: root
      vars_files:
        - "vars/common.yml"
        - [ "vars/$facter_operatingsystem.yml", "vars/os_defaults.yml" ]
      tasks:
      - name: make sure apache is running
        action: service name=$apache state=running

.. note::
   The variable (`$facter_operatingsystem`) is being interpolated into
   the list of filenames being defined for vars_files.

As a reminder, the various YAML files contain just keys and values::

    ---
    # for vars/CentOS.yml
    apache: httpd
    somethingelse: 42

How does this work?  If the operating system was 'CentOS', the first file Ansible would try to import
would be 'vars/CentOS.yml', followed up by '/vars/os_defaults.yml' if that file
did not exist.   If no files in the list were found, an error would be raised.
On Debian, it would instead first look towards 'vars/Debian.yml' instead of 'vars/CentOS.yml', before
falling back on 'vars/os_defaults.yml'. Pretty simple.

To use this conditional import feature, you'll need facter or ohai installed prior to running the playbook, but
you can of course push this out with Ansible if you like::

    # for facter
    ansible -m yum -a "pkg=facter ensure=installed"
    ansible -m yum -a "pkg=ruby-json ensure=installed"

    # for ohai
    ansible -m yum -a "pkg=ohai ensure=installed"

Ansible's approach to configuration -- separating variables from tasks, keeps your playbooks
from turning into arbitrary code with ugly nested ifs, conditionals, and so on - and results
in more streamlined & auditable configuration rules -- especially because there are a
minimum of decision points to track.

Loops
`````

To save some typing, repeated tasks can be written in short-hand like so::

    - name: add several users
      action: user name=$item state=present groups=wheel
      with_items:
         - testuser1
         - testuser2

If you have defined a YAML list in a variables file, or the 'vars' section, you can also do::

    with_items: $somelist

The above would be the equivalent of::

    - name: add user testuser1
      action: user name=testuser1 state=present groups=wheel
    - name: add user testuser2
      action: user name=testuser2 state=present groups=wheel

The yum and apt modules use with_items to execute fewer package manager transactions.

Note that the types of items you iterate over with 'with_items' do not have to be simple lists of strings.
If you have a list of hashes, you can reference subkeys using things like::

    ${item.subKeyName}

Lookup Plugins - Accessing Outside Data
```````````````````````````````````````

.. versionadded: 0.8

Various 'lookup plugins' allow additional ways to iterate over data.  Ansible will have more of these
over time.  You can write your own, as is covered in the API section.  Each typically takes a list and
can accept more than one parameter.

'with_fileglob' matches all files in a single directory, non-recursively, that match a pattern.  It can
be used like this::

    ----
    - hosts: all

      tasks:

        # first ensure our target directory exists
        - action: file dest=/etc/fooapp state=directory

        # copy each file over that matches the given pattern
        - action: copy src=$item dest=/etc/fooapp/ owner=root mode=600
          with_fileglob:
            - /playbooks/files/fooapp/*

'with_file' loads data in from a file directly::

        - action: authorized_key user=foo key=$item
          with_file:
             - /home/foo/.ssh/id_rsa.pub

As an alternative, lookup plugins can also be accessed in variables like so::

        vars:
            motd_value: $FILE(/etc/motd)
            hosts_value: $LOOKUP(file,/etc/hosts)

.. versionadded: 0.9

Many new lookup abilities were added in 0.9.  Remeber lookup plugins are run on the "controlling" machine::

    ---
    - hosts: all

      tasks:

         - action: debug msg="$item is an environment variable"
           with_env:
             - HOME
             - LANG

         - action: debug msg="$item is a line from the result of this command"
           with_lines:
             - cat /etc/motd

         - action: debug msg="$item is the raw result of running this command"
           with_pipe:
              - date

         - action: debug msg="$item is value in Redis for somekey"
           with_redis_kv:
             - redis://localhost:6379,somekey

         - action: debug msg="$item is a DNS TXT record for example.com"
           with_dnstxt:
             - example.com

         - action: debug msg="$item is a value from evaluation of this template"
           with_template:
              - ./some_template.j2

You can also assign these to variables, should you wish to do this instead, that will be evaluated
when they are used in a task (or template)::

    vars:
        redis_value: $LOOKUP(redis,redis://localhost:6379,info_${inventory_hostname})
        auth_key_value: $FILE(/home/mdehaan/.ssh/id_rsa.pub)

    tasks:
        - debug: msg=Redis value for host is $redis_value

.. versionadded: 1.0

'with_sequence' generates a sequence of items in ascending numerical order. You
can specify a start, end, and an optional step value.

Arguments can be either key-value pairs or as a shortcut in the format
"[start-]end[/stride][:format]".  The format is a printf style string.

Numerical values can be specified in decimal, hexadecimal (0x3f8) or octal (0600).
Negative numbers are not supported.  This works as follows::

    ---
    - hosts: all

      tasks:

        # create groups
        - group: name=evens state=present
        - group: name=odds state=present

        # create 32 test users
        - user: name=$item state=present groups=odds
          with_sequence: 32/2:testuser%02x

        - user: name=$item state=present groups=evens
          with_sequence: 2-32/2:testuser%02x

        # create a series of directories for some reason
        - file: dest=/var/stuff/$item state=directory
          with_sequence: start=4 end=16

        # a simpler way to use the sequence plugin
        # create 4 groups
        - group: name=group${item} state=present
          with_sequence: count=4

.. versionadded: 1.1

'with_password' and associated macro "$PASSWORD" generate a random plaintext password and store it in
a file at a given filepath.  Support for crypted save modes (as with vars_prompt) are pending.  If the file exists previously, "$PASSWORD"/'with_password' will retrieve its contents, behaving just like $FILE/'with_file'. Usage of variables like "${inventory_hostname}" in the filepath can be used to set up random passwords per host.

Generated passwords contain a random mix of upper and lowercase ASCII letters, the
numbers 0-9 and punctuation (". , : - _"). The default length of a generated password is 30 characters. This length can be changed by passing an extra parameter::

    ---
    - hosts: all

      tasks:

        # create a mysql user with a random password:
        - mysql_user: name=$client
                      password=$PASSWORD(credentials/$client/$tier/$role/mysqlpassword)
                      priv=$client_$tier_$role.*:ALL

        (...)

        # dump a mysql database with a given password (this example showing the other form).
        - mysql_db: name=$client_$tier_$role
                    login_user=$client
                    login_password=$item
                    state=dump
                    target=/tmp/$client_$tier_$role_backup.sql
          with_password: credentials/$client/$tier/$role/mysqlpassword

        # make a longer or shorter password by appending a length parameter:
        - mysql_user: name=some_name
                      password=$item
          with_password: files/same/password/everywhere length=15

Setting the Environment (and Working With Proxies)
``````````````````````````````````````````````````

.. versionadded: 1.1

It is quite possible that you may need to get package updates through a proxy, or even get some package
updates through a proxy and access other packages not through a proxy.  Ansible makes it easy for you
to configure your environment by using the 'environment' keyword.  Here is an example::

    - hosts: all
      user: root

      tasks:

        - apt: name=cobbler state=installed
          environment:
            http_proxy: http://proxy.example.com:8080

The environment can also be stored in a variable, and accessed like so::

    - hosts: all
      user: root

      # here we make a variable named "env" that is a dictionary
      vars:
        proxy_env:
          http_proxy: http://proxy.example.com:8080

      tasks:

        - apt: name=cobbler state=installed
          environment: $proxy_env

While just proxy settings were shown above, any number of settings can be supplied.  The most logical place
to define an environment hash might be a group_vars file, like so::

    ----
    # file: group_vars/boston

    ntp_server: ntp.bos.example.com
    backup: bak.bos.example.com
    proxy_env:
      http_proxy: http://proxy.bos.example.com:8080
      https_proxy: http://proxy.bos.example.com:8080

Getting values from files
`````````````````````````

.. versionadded:: 0.8

Sometimes you'll want to include the content of a file directly into a playbook.  You can do so using a macro.
This syntax will remain in future versions, though we will also will provide ways to do this via lookup plugins (see "More Loops") as well.  What follows
is an example using the authorized_key module, which requires the actual text of the SSH key as a parameter::

    tasks:
        - name: enable key-based ssh access for users
          authorized_key: user=$item key='$FILE(/keys/$item)'
          with_items:
             - pinky
             - brain
             - snowball

The "$PIPE" macro works just like file, except you would feed it a command string instead.  It executes locally, not remotely, as does $FILE.

Because Ansible uses lazy evaluation, a "$PIPE" macro will be executed each time it is used. For
example, it will be executed separately for each host, and if it is used in a variable definition,
it will be executed each time the variable is evaluated.

Selecting Files And Templates Based On Variables
````````````````````````````````````````````````

Sometimes a configuration file you want to copy, or a template you will use may depend on a variable.
The following construct selects the first available file appropriate for the variables of a given host, which is often much cleaner than putting a lot of if conditionals in a template.

The following example shows how to template out a configuration file that was very different between, say, CentOS and Debian::

    - name: template a file
      action: template src=$item dest=/etc/myapp/foo.conf
      first_available_file:
        - /srv/templates/myapp/${ansible_distribution}.conf
        - /srv/templates/myapp/default.conf

first_available_file is only available to the copy and template modules.

Asynchronous Actions and Polling
````````````````````````````````

By default tasks in playbooks block, meaning the connections stay open
until the task is done on each node.  If executing playbooks with
a small parallelism value (aka ``--forks``), you may wish that long
running operations can go faster.  The easiest way to do this is
to kick them off all at once and then poll until they are done.

You will also want to use asynchronous mode on very long running
operations that might be subject to timeout.

To launch a task asynchronously, specify its maximum runtime
and how frequently you would like to poll for status.  The default
poll value is 10 seconds if you do not specify a value for `poll`::

    ---
    - hosts: all
      user: root
      tasks:
      - name: simulate long running op (15 sec), wait for up to 45, poll every 5
        action: command /bin/sleep 15
        async: 45
        poll: 5

.. note::
   There is no default for the async time limit.  If you leave off the
   'async' keyword, the task runs synchronously, which is Ansible's
   default.

Alternatively, if you do not need to wait on the task to complete, you may
"fire and forget" by specifying a poll value of 0::

    ---
    - hosts: all
      user: root
      tasks:
      - name: simulate long running op, allow to run for 45, fire and forget
        action: command /bin/sleep 15
        async: 45
        poll: 0

.. note::
   You shouldn't "fire and forget" with operations that require
   exclusive locks, such as yum transactions, if you expect to run other
   commands later in the playbook against those same resources.

.. note::
   Using a higher value for ``--forks`` will result in kicking off asynchronous
   tasks even faster.  This also increases the efficiency of polling.

Local Playbooks
```````````````

It may be useful to use a playbook locally, rather than by connecting over SSH.  This can be useful
for assuring the configuration of a system by putting a playbook on a crontab.  This may also be used
to run a playbook inside a OS installer, such as an Anaconda kickstart.

To run an entire playbook locally, just set the "hosts:" line to "hosts:127.0.0.1" and then run the playbook like so::

    ansible-playbook playbook.yml --connection=local

Alternatively, a local connection can be used in a single playbook play, even if other plays in the playbook
use the default remote connection type::

    hosts: 127.0.0.1
    connection: local

Turning Off Facts
`````````````````

If you know you don't need any fact data about your hosts, and know everything about your systems centrally, you
can turn off fact gathering.  This has advantages in scaling ansible in push mode with very large numbers of
systems, mainly, or if you are using Ansible on experimental platforms.   In any play, just do this::

    - hosts: whatever
      gather_facts: no

Pull-Mode Playbooks
```````````````````

The use of playbooks in local mode (above) is made extremely powerful with the addition of `ansible-pull`.
A script for setting up ansible-pull is provided in the examples/playbooks directory of the source
checkout.

The basic idea is to use Ansible to set up a remote copy of ansible on each managed node, each set to run via
cron and update playbook source via git.  This inverts the default push architecture of ansible into a pull
architecture, which has near-limitless scaling potential.  The setup playbook can be tuned to change
the cron frequency, logging locations, and parameters to ansible-pull.

This is useful both for extreme scale-out as well as periodic remediation.  Usage of the 'fetch' module to retrieve
logs from ansible-pull runs would be an excellent way to gather and analyze remote logs from ansible-pull.

Register Variables
``````````````````

.. versionadded:: 0.7

Often in a playbook it may be useful to store the result of a given command in a variable and access
it later.  Use of the command module in this way can in many ways eliminate the need to write site specific facts, for
instance, you could test for the existance of a particular program.

The 'register' keyword decides what variable to save a result in.  The resulting variables can be used in templates, action lines, or only_if statements.  It looks like this (in an obviously trivial example)::

    - name: test play
      hosts: all

      tasks:

          - action: shell cat /etc/motd
            register: motd_contents

          - action: shell echo "motd contains the word hi"
            only_if: "'${motd_contents.stdout}'.find('hi') != -1"


Rolling Updates
```````````````

.. versionadded:: 0.7

By default ansible will try to manage all of the machines referenced in a play in parallel.  For a rolling updates
use case, you can define how many hosts ansible should manage at a single time by using the ''serial'' keyword::


    - name: test play
      hosts: webservers
      serial: 3

In the above example, if we had 100 hosts, 3 hosts in the group 'webservers'
would complete the play completely before moving on to the next 3 hosts.

Delegation
``````````

.. versionadded:: 0.7

If you want to perform a task on one host with reference to other hosts, use the 'delegate_to' keyword on a task.
This is ideal for placing nodes in a load balanced pool, or removing them.  It is also very useful for controlling
outage windows.  Using this with the 'serial' keyword to control the number of hosts executing at one time is also
a good idea::

    ---
    - hosts: webservers
      serial: 5

      tasks:
      - name: take out of load balancer pool
        action: command /usr/bin/take_out_of_pool $inventory_hostname
        delegate_to: 127.0.0.1

      - name: actual steps would go here
        action: yum name=acme-web-stack state=latest

      - name: add back to load balancer pool
        action: command /usr/bin/add_back_to_pool $inventory_hostname
        delegate_to: 127.0.0.1


These commands will run on 127.0.0.1, which is the machine running Ansible. There is also a shorthand syntax that 
you can use on a per-task basis: 'local_action'. Here is the same playbook as above, but using the shorthand 
syntax for delegating to 127.0.0.1::

    ---
    # ...
      tasks:
      - name: take out of load balancer pool
        local_action: command /usr/bin/take_out_of_pool $inventory_hostname

    # ...

      - name: add back to load balancer pool
        local_action: command /usr/bin/add_back_to_pool $inventory_hostname

A common pattern is to use a local action to call 'rsync' to recursively copy files to the managed servers.
Here is an example::

    ---
    # ...
      tasks:
      - name: recursively copy files from management server to target
        local_action: command rsync -a /path/to/files $inventory_hostname:/path/to/target/

Note that you must have passphrase-less SSH keys or an ssh-agent configured for this to work, otherwise rsync
will need to ask for a passphrase.

Fireball Mode
`````````````

.. versionadded:: 0.8

Ansible's core connection types of 'local', 'paramiko', and 'ssh' are augmented in version 0.8 and later by a new extra-fast
connection type called 'fireball'.  It can only be used with playbooks and does require some additional setup
outside the lines of ansible's normal "no bootstrapping" philosophy.  You are not required to use fireball mode
to use Ansible, though some users may appreciate it.

Fireball mode works by launching a temporary 0mq daemon from SSH that by default lives for only 30 minutes before
shutting off.  Fireball mode once running uses temporary AES keys to encrypt a session, and requires direct
communication to given nodes on the configured port.  The default is 5099.  The fireball daemon runs as any user you
set it down as.  So it can run as you, root, or so on.  If multiple users are running Ansible as the same batch of hosts,
take care to use unique ports.

Fireball mode is roughly 10 times faster than paramiko for communicating with nodes and may be a good option
if you have a large number of hosts::

    ---

    # set up the fireball transport
    - hosts: all
      gather_facts: no
      connection: ssh # or paramiko
      sudo: yes
      tasks:
          - action: fireball

    # these operations will occur over the fireball transport
    - hosts: all
      connection: fireball
      tasks:
          - action: shell echo "Hello ${item}"
            with_items:
                - one
                - two

In order to use fireball mode, certain dependencies must be installed on both ends.   You can use this playbook as a basis for initial bootstrapping on
any platform.  You will also need gcc and zeromq-devel installed from your package manager, which you can of course also get Ansible to install::

    ---
    - hosts: all
      sudo: yes
      gather_facts: no
      connection: ssh
      tasks:
          - action: easy_install name=pip
          - action: pip name=$item state=present
            with_items:
              - pyzmq
              - pyasn1
              - PyCrypto
              - python-keyczar

Fedora and EPEL also have Ansible RPM subpackages available for fireball-dependencies.

Also see the module documentation section.


Understanding Variable Precedence
`````````````````````````````````

You have already learned about inventory host and group variables, 'vars', and 'vars_files'.

If a variable name is defined in more than one place with the same name, priority is as follows
to determine which place sets the value of the variable.  Lower numbered items have the highest
priority.

1.  Any variables specified with --extra-vars (-e) on the ansible-playbook command line.

2.  Variables loaded from YAML files mentioned in 'vars_files' in a playbook.

3.  facts, whether built in or custom, or variables assigned from the 'register' keyword.

4.  variables passed to parameterized task include statements.

5.  'vars' as defined in the playbook.

6.  Host variables from inventory.

7.  Group variables from inventory in inheritance order.  This means if a group includes a sub-group, the variables
    in the subgroup have higher precedence.

Therefore, if you want to set a default value for something you wish to override somewhere else, the best
place to set such a default is in a group variable.  The 'group_vars/all' file makes an excellent place to put global
variables that are true across your entire site, since everything has higher priority than these values.


Check Mode ("Dry Run") --check
```````````````````````````````

.. versionadded:: 1.1

When ansible-playbook is executed with --check it will not make any changes on remote systems.  Instead, any module
instrumented to support 'check mode' (which contains the primary core modules, but it is not required that all modules do
this) will report what changes they would have made.  Other modules that do not support check mode will also take no
action, but just will not report what changes they might have made.

Check mode is just a simulation, and if you have steps that use conditionals that depend on the results of prior commands,
it may be less useful for you.  However it is great for one-node-at-time basic configuration management use cases.

Example::

    ansible-playbook foo.yml --check

Showing Differences with --diff
```````````````````````````````

.. versionadded:: 1.1

The --diff option to ansible-playbook works great with --check (detailed above) but can also be used by itself.  When this flag is supplied, if any templated files on the remote system are changed, and the ansible-playbook CLI will report back
the textual changes made to the file (or, if used with --check, the changes that would have been made).  Since the diff
feature produces a large amount of output, it is best used when checking a single host at a time, like so::

    ansible-playbook foo.yml --check --diff --limit foo.example.com

Dictionary & Nested (Complex) Arguments
```````````````````````````````````````

As a review, most tasks in ansbile are of this form::

    tasks:

      - name: ensure the cobbler package is installed
        yum: name=cobbler state=installed

However, in some cases, it may be useful to feed arguments directly in from a hash (dictionary).  In fact, a very small
number of modules (the CloudFormations module is one) actually require complex arguments.  They work like this::

    tasks:

      - name: call a module that requires some complex arguments
        foo_module:
           fibonacci_list:
             - 1
             - 1
             - 2
             - 3
           my_pets:
             dogs:
               - fido
               - woof
             fish:
               - limpet
               - nemo
               - ${other_fish_name}

You can of course use variables inside these, as noted above.

If using local_action, you can do this::

    - name: call a module that requires some complex arguments
      local_action:
        module: foo_module
        arg1: 1234
        arg2: 'asdf'

Which of course means, though more verbose, this is also technically legal syntax::

    - name: foo
      template: { src: '/templates/motd.j2', dest: '/etc/motd' }

Style Points
````````````

Ansible playbooks are colorized.  If you do not like this, set the ANSIBLE_NOCOLOR=1 environment variable.

Ansible playbooks also look more impressive with cowsay installed, and we encourage installing this package.

.. seealso::

   :doc:`YAMLSyntax`
       Learn about YAML syntax
   :doc:`playbooks`
       Review the basic playbook features
   :doc:`bestpractices`
       Various tips about playbooks in the real world
   :doc:`modules`
       Learn about available modules
   :doc:`moduledev`
       Learn how to extend Ansible by writing your own modules
   :doc:`patterns`
       Learn about how to select hosts
   `Github examples directory <https://github.com/ansible/ansible/tree/devel/examples/playbooks>`_
       Complete playbook files from the github project source
   `Mailing List <http://groups.google.com/group/ansible-project>`_
       Questions? Help? Ideas?  Stop by the list on Google Groups


