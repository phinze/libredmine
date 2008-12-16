========================
libredmine
========================

A python library and command line client for interfacing with the Redmine
project management web application

about
==============================

Very early stages now... mostly ideas like this::

  09:21 <phinze> i'm specing out a command line client tentatively called 'rdm'
  that mostly mirrors svn and allows you to check on your tickets and hopefully
  eventually edit them 

  09:21 <phinze> i'd like to see something that throws you into $EDITOR with a
  template that you change and then parses it out and sends it back to the webapp


Mostly, the plan for this project consists of two parts:

``libredmine``
    a python abstraction of an instance of Redmine with a www-mechanize backend 

``rdm``
    a command-line client for interfacing with Redmine that leverages the python library

TODO
==============================

lib:
- Ability to sort Issues by Multiple Keys: project, priority, status, etc.
- Write back to server updated tickets?

client:
- Stay alive to store password and fetch again?
- Keep a cache in a tmp file and only update from site periodically?
- Come up with a draft CLI... `red [command]` perhaps?
