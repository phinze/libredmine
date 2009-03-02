require 'rubygems'
require 'mechanize'
require 'hpricot'
require 'fastercsv'
require 'logger'
require 'termios'
require 'uri'

# Represents one issue in Redmine.
module Redmine
  class Issue
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

    def self.from_csv(csv_list)
      issues = {}
      csv_list.each do |row|
        next if row[0] == "#"

        red = Issue.new(*row)
        issues[red.id] = red
      end
      return issues
    end

    def self.from_mechanize_page(id, page)
      issue = self.new(id)
      form = page.form_with(:action => "/issues/#{id}/edit")
      issue.status = form.['issue[status_id]'].options.find { |o| o.value == form['issue[status_id]'] }.text
      issue.project
      debugger
      tmp = 1
    end
  end

  class IssueQuery
    NEW = 1
    ASSIGNED = 2
    RESOLVED = 3
    FEEDBACK = 4
    CLOSED = 5
    REJECTED = 6
    IMPEDED = 7

    def initialize(base_url)
      @url = base_url + 'issues?set_filter=1&'
    end

    def assigned_to_user(user_id)
      @url = @url + "assigned_to_id=#{user_id}&"
    end

    def with_status(status_id)
      @url = @url + "status_id=#{status_id}&"
    end

  end

  # Represents an instance of a Redmine site
  class Site

    attr_reader :logged_in

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

    def issues
      return Redmine::IssueQuery.new(@url)
    end

    def query(q)
      raise 'must be logged in' unless @logged_in
      issues = []
      @agent.get(q) do |page|
        csv_page = page.link_with(:text => 'CSV').click
        FasterCSV.parse(csv_page.content) do |row|
          next if row[0] == "#"
          issues << Issue.new(*row)
        end
      end
      return issues
    end

    def get_issue(issue_number)
      raise 'must be logged in' unless @logged_in
      @agent.get(URI::join(@url, "/issues/show/#{issue_number.to_s}")) do |page|
        return Issue.from_mechanize_page(page)
      end
    end

    private 

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
  end
end
