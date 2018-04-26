require 'jira-ruby'
require 'typhoeus'

module JIRA
  module Resource
    class Issue < JIRA::Base
      def to_hash
        JSON.parse(self.to_json, symbolize_names: true)
      end

      def original_estimate
        self.fields.fetch('customfield_10006')
      end

      def time_spent
        self.fields.fetch('timespent').to_f/3600.0
      end

      def assignee
        self.fields.fetch('assignee')&.fetch('name')
      end

      def sprint
        str = self.fields.fetch('customfield_10005').try(:last)
        unless str.nil?
            str = str[/name=[^,]+,/]&.gsub('name=','')&.gsub(',','')
        end
        str
      end

      def key
        self.attrs['key']
      end

      def url
        @attrs['self'].gsub(/rest.*$/,"browse/#{key}")
      end

      def status
        self.fields['status']['name']
      end

      def summary
        self.fields['summary']
      end

      def custom_fields
        self.fields.keys.select { |k| k.include?('custom') }
      end

      def project
        self.fields['project']['key']
      end

      def worklog
        unless @worklog
          r = Typhoeus::Request.get("http://jira.rozum.com/rest/api/2/issue/#{self.attrs['key']}/worklog/", userpwd: "mikhail.chuprynski:m0a16v6uuhEfOB5KL6gy", headers: {Accept: "application/json"})
          worklog_array = JSON.parse(r.body, symbolize_names: true)[:worklogs]
          @worklog = worklog_array.map { |w| {author: w[:author][:name], logged: w[:timeSpentSeconds]/3600.0, date: Date.parse(w[:started]), issue: self.attrs['key']} }
        end
        @worklog
      end

      def updated_at
        Time.parse self.fields['updated']
      end
    end

    class Project < JIRA::Base
      def to_hash
        JSON.parse(self.to_json, symbolize_names: true)
      end

      def all_issues
        @all_issues ||= self.issues(maxResults: 1000)
      end

      def active_users
        all_issues.map { |i| i.fields.fetch('assignee')&.fetch('name') }.uniq.compact.sort
      end

      def user_issues(user_key)
        all_issues.select { |i| i.assignee == user_key }
      end

      def get_issue(key)
        all_issues.select { |i| i.key == key }.first
      end
    end
  end
end

class JiraRails
  OPTIONS = {
      username: 'mikhail.chuprynski',
      password: ENV['JIRA_PASS'],
      site: 'http://jira.rozum.com/',
      port: '80',
      context_path: '',
      auth_type: :basic,
      use_ssl: false
  }

  def self.client
    JIRA::Client.new(OPTIONS)
  end

end