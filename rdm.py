#!/usr/bin/python
import os  # for env variables
import pdb # for debugging
import getpass
from libredmine import Redmine, RedmineIssue

###
### Main Program Execution
###

print "Opening Redmine..."
rm = Redmine('https://redmine.research.uiowa.edu/')

print "Logging In..."

u = getpass.getuser()
p = getpass.getpass('Password:')
rm.login(u, p)


print "Getting Issues..."
issues_hash = rm.get_issues()
issues = issues_hash.values()

# sort by project
issues.sort(key=lambda obj: obj.project)

# File output

last_project = ''
for issue in issues:
    if issue.project != last_project:
        last_project = issue.project
        print issue.project + ':'
    print("  " + issue.get_header())
