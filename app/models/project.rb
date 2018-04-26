require 'jira'

class Project < ApplicationRecord
  has_many :snapshots

  def self.get_list
    projects = JiraRails.client.Project.all
    keys = projects.map(&:key)
    keys.each do |key|
      Project.find_or_create_by(name: key)
    end
    keys
  end

  def client
    @client ||= JiraRails.client
  end

  def table(period = 15)
    s = snapshots.find_by(date: Date.today)
    if s.nil?
      table = {}
      table['pivot'] = {}
      team(period).each do |member|
        dates(period).each do |date|
          table['pivot'][member] ||= {}
          logged = 0
          worklog(period).select { |w| w[:author] == member and w[:date] == date }.each do |worklog|
            logged += worklog[:logged]
          end
          table['pivot'][member][date.to_s] = logged
        end
      end
      table['issues'] = issues(period).map do |issue|
        {
            key: issue.key,
            assignee: issue.assignee,
            time_spent: issue.time_spent,
            original_estimate: issue.original_estimate,
            url: issue.url,
            summary: issue.summary,
            sprint: issue.sprint,
            status: issue.status
        }
      end
      table['worklog'] = worklog(period)
      s = snapshots.create(date: Date.today, table: table)
    end
    s.table
  end

  def team(days_ago)
    @team ||= worklog(days_ago).map { |w| w[:author] }.uniq
  end

  def worklog(days_ago)
    @worklog ||= issues(days_ago).map { |i| i.worklog }.flatten
  end

  def jira_instance
    @jira_instance ||= client.Project.find(name)
  end

  def issues(days_ago)
    @issues ||= jira_instance.all_issues.select { |i| i.time_spent > 0 and i.updated_at > Date.today - days_ago }
  end

  def dates(days_ago)
    worklog(days_ago).map { |w| w[:date] }.uniq.sort.select { |w| w > Date.today - days_ago }
  end
end


# project = client.Project.find(project_name)
# issues = project.all_issues.select { |i| i.time_spent > 0 and i.updated_at > DateTime.now - 15 }
#
# issues.each do |issue|
#   issue.worklog
# end

# t1 = Time.now
# p t1-t
# # w = client.Worklog.find( '', :issue_id => 'JAVA-82')
#
# project_worklog = issues.map { |i| i.worklog }.flatten
# team = project_worklog.map { |w| w[:author] }.uniq
# dates = project_worklog.map { |w| w[:date] }.uniq.sort.select { |w| w > DateTime.now - 15 }
#
#
# pp 'worklog'
#
# CSV.open(project_name + '.csv', 'wb') do |csv|
#   csv << [''] + dates.map(&:to_s) + ['total']
#   team.each do |member|
#     row = [member]
#     total = 0
#     dates.each do |date|
#       row << table[member][date.to_s].round(2)
#       total += table[member][date.to_s]
#     end
#     row << total
#     csv << row
#   end
# end

