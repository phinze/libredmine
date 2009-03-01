require 'rubygems'
require 'mechanize'
require 'hpricot'
require 'fastercsv'
require 'logger'
require 'termios'
require 'uri'
require 'ruby-debug'

# Represents one issue in Redmine.
class RedmineIssue
  attr_accessor :id, :status, :project, :tracker, :priority, :subject,
                :assigned_to, :category, :target_version, :author, :start,
                :due_date, :percent_done, :estimated_time, :created, :updated,
                :date_deployed, :description

  def initialize(id, status=nil, project=nil, tracker=nil, priority=nil,
                 subject=nil, assigned_to=nil, category=nil, target_version=nil,
                 author=nil, start=nil, due_date=nil, percent_done=nil,
                 estimated_time=nil, created=nil, updated=nil,
                 date_deployed=nil, description=nil) 
      @id             = id
      @status         = status
      @project        = project
      @tracker        = tracker
      @priority       = priority
      @subject        = subject
      @assigned_to    = assigned_to
      @category       = category
      @target_version = target_version
      @author         = author
      @start          = start
      @due_date       = due_date
      @percent_done   = percent_done
      @estimated_time = estimated_time
      @created        = created
      @updated        = updated
      @date_deployed  = date_deployed
      @description    = description
  end

  def to_s 
    return [@id, @status, @project, @tracker, @priority, @subject, @assigned_to,
            @category, @target_version, @author, @start, @due_date, @percent_done,
            @estimated_time, @created, @updated, @date_deployed, @description].join(';')
  end

  def get_header
    return @id + ': ' + @subject + ' (' + @status + ')'
  end

  def self.issues_from_csv(csv_list)
    issues = {}
    csv_list.each do |row|
      next if row[0] == "#"

      red = RedmineIssue.new(*row)
      issues[red.id] = red
    end
    return issues
  end
end


# Represents an instance of Redmine
class Redmine
  def initialize(url)
    @url = url
    @agent = WWW::Mechanize.new { |a| a.log = Logger.new(File.join('mech.log')) }
    @logged_in = false
  end

  def login(user=nil, passwd=nil)
		user ||= `who am i | awk '{print $1}'`.strip
		passwd ||= input_passwd(user)

		# Get the login page
    @agent.get(URI::join(@url, "login")) do |page|

			# Fill out the login form
			my_page = page.form_with(:action => '/login') do |f|
				f.username = user
				f.password = passwd
			end.click_button

			raise if my_page.nil?
		end

    @logged_in = true
  end

	def input_passwd(user)
    oldt = Termios.tcgetattr($stdin)
    newt = oldt.dup
    newt.lflag &= ~Termios::ECHO
    Termios.tcsetattr($stdin, Termios::TCSANOW, newt)
    print "password for #{user}> "
    passwd = $stdin.gets.strip
    Termios.tcsetattr($stdin, Termios::TCSANOW, oldt)
    puts "\n"
		return passwd
	end

  def get_my_issues
    raise 'must be logged in' unless @logged_in
    issues = []
    @agent.get(URI::join(@url, "issues?assigned_to_id=me&set_filter=1")) do |page|
			csv_page = page.link_with(:text => 'CSV').click
      FasterCSV.parse(csv_page.content) do |row|
        issues << RedmineIssue.new(*row)
      end
		end
    return issues
  end

  def get_issue(issue_number)
    return if not @logged_in
    @agent.open(urlparse.urljoin(@url, "issues/show/" + str(issue_number)))
    return false
  end
end
    
# Init
redmine = Redmine.new('https://redmine.research.uiowa.edu/')
redmine.login
my_issues = redmine.get_my_issues

# Sort by project
my_issues.sort! {|a, b| a.project <=> b.project }

# Print w/ project headers
last_proj = nil
my_issues.each do |issue|
  if issue.project != last_proj:
    last_proj = issue.project 
    puts issue.project + ':'
  end
  puts "  " + issue.get_header()
end

