#!/usr/bin/python
import os        # for env variables
import pdb       # for debugging
import sys
import optparse  # for argument processing
import getpass   # for asking about password
from libredmine import Redmine, RedmineIssue

def init():
    print "Opening Redmine..."
    rdm = Redmine('https://redmine.research.uiowa.edu/')

    print "Logging In..."

    u = getpass.getuser()
    p = getpass.getpass('Password:')
    rdm.login(u, p)
    return rdm

def list_all_issues(issues_hash):
    print "Getting Issues..."
    issues = issues_hash.values()

    # sort by project
    issues.sort(key=lambda obj: obj.project)

    last_project = ''
    for issue in issues:
        if issue.project != last_project:
            last_project = issue.project
            print issue.project + ':'
        print("  " + issue.get_header())

def print_issue(issue):
    print "NYI: Printing issue " + str(issue)

###
### Main Program Execution
###

def main(args):
    p = optparse.OptionParser()
    p.add_option("-i", "--issue", 
                 action="store", type="int", dest="issue",
                 help="show details about specific issue")
    (options, args) = p.parse_args(args)

    redmine = init()

    if options.issue:
        issu = redmine.get_issue(options.issue)
        print_issue(issue)
    else:
        list_all_issues(redmine.get_issues())


if __name__ == '__main__':
    main(sys.argv[1:])

