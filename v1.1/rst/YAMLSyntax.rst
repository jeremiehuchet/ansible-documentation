YAML Syntax
===========

.. image:: http://ansible.cc/docs/_static/ansible_fest_2013.png
   :alt: ansiblefest 2013
   :target: http://ansibleworks.com/fest

This page provides a basic overview of correct YAML syntax, which is how Ansible
playbooks (our configuration management language) are expressed.  

We use YAML because it is easier to read and write for humans than other common 
data formats like XML or JSON.  Further, there are libraries available for reading
and writing YAML in most programming languages.  

You may also wish to read :doc:`playbooks` at the same time to see how this
is used in practice.


YAML Basics
-----------

For `ansible`, nearly every YAML file starts with a list.   
Each item in the list is a list of key/value pairs, commonly
called a "hash" or a "dictionary".  So, we need to know how
to write lists and dictionaries in YAML.

There's another small quirk to YAML.  All YAML files (regardless of their association with
`ansible` or not) should start with ``---``.  This is just a YAML
format thing that means "this is the start of a document".

All members of a list are lines beginning at the same indentation level starting
with a ``-`` (dash) character::

    ---
    # A list of tasty fruits
    - Apple
    - Orange
    - Strawberry
    - Mango

A dictionary is represented in a simple ``key:`` and ``value`` form::

    ---
    # An employee record
    name: Example Developer
    job: Developer
    skill: Elite

Dictionaries can also be represented in an abbreviated form if you really want to::

    ---
    # An employee record
    {name: Example Developer, job: Developer, skill: Elite}

.. _truthiness:

Ansible doesn't really use these too much, but you can also specify a 
boolean value (true/false) in several forms::

    ---
    create_key: yes
    needs_agent: no
    knows_oop: True
    likes_emacs: TRUE
    uses_cvs: false

Let's combine what we learned so far in an arbitary YAML example.  This really
has nothing to do with Ansible, but will give you a feel for the format::

    ---
    # An employee record
    name: Example Developer
    job: Developer
    skill: Elite
    employed: True
    foods:
        - Apple
        - Orange
        - Strawberry
        - Mango
    languages:
        ruby: Elite
	python: Elite
	dotnet: Lame

That's all you really need to know about YAML to get started writing
`Ansible` playbooks.

Gotchas
-------

While YAML is generally friendly, the following is going to be a YAML syntax error:

    foo: somebody said I should put a colon here: so I did

You will want to quote any hash values using colons, like so:

    foo: "somebody said I should put a colon here: so I did"

And then the colon will be preserved.

.. seealso::

   :doc:`playbooks`
       Learn what playbooks can do and how to write/run them.
   `YAMLLint <http://yamllint.com/>`_
       YAML Lint (online) helps you debug YAML syntax if you are having problems
   `Github examples directory <https://github.com/ansible/ansible/tree/devel/examples/playbooks>`_
       Complete playbook files from the github project source
   `Mailing List <http://groups.google.com/group/ansible-project>`_
       Questions? Help? Ideas?  Stop by the list on Google Groups
   `irc.freenode.net <http://irc.freenode.net>`_
       #ansible IRC chat channel

