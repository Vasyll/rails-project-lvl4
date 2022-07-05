# frozen_string_literal: true

require 'json'

class CheckRepositoryJob < ApplicationJob
  queue_as :default

  def perform(check_id)
    check = Repository::Check.find(check_id)
    check.start!
    repository = Repository.find(check.repository_id)

    path_temp = "./tmp/hexlet_quality_repositories/#{repository.full_name}"
    stdin, stdout, stderr, wait_thr = Open3.popen3("git clone #{repository.clone_url} #{path_temp}")
    puts "==git clone== #{stdout.read} #{stderr.read} #{wait_thr.value.exitstatus}"

    if repository.language == 'javascript'
      stdin, stdout, stderr, wait_thr = Open3.popen3("yarn run eslint #{path_temp} -f json >#{path_temp}/eslint.json")
      puts "==eslint== #{stdout.read} #{stderr.read} #{wait_thr.value.exitstatus}"

      eslint = JSON.parse(File.readlines("#{path_temp}/eslint.json")[2])

      result = []
      eslint.each do |file, _value|
        next if file['errorCount'].zero?

        result << { 'file_path' => file['filePath'] }
        messages = file['messages']
        messages.each do |message, _value|
          result << {
            'message' => message['message'],
            'rule' => message['ruleId'],
            'line_column' => "#{message['line']}:#{message['column']}"
          }
        end
      end
      check.result = result
      check.issues_count = eslint['errorCount']
    end

    if repository.language == 'ruby'
      stdin, stdout, stderr, wait_thr = Open3.popen3("bundle exec rubocop #{path_temp} -f json >#{path_temp}/rubocop.json")
      puts "==rubocop== #{stdout.read} #{stderr.read} #{wait_thr.value.exitstatus}"

      rubocop = JSON.parse(File.read("#{path_temp}/rubocop.json"))

      result = []
      files = rubocop['files']

      files.each do |file, _value|
        next if file['offenses'].count.zero?

        result << { 'file_path' => file['path'] }
        offenses = file['offenses']
        offenses.each do |offense, _value|
          result << {
            'message' => offense['message'],
            'rule' => offense['cop_name'],
            'line_column' => "#{offense['line']}:#{offense['column']}"
          }
        end
      end
      check.result = result
      check.issues_count = rubocop['summary']['offense_count']
    end

    stdin, stdout, stderr, wait_thr = Open3.popen3("git -C #{path_temp} rev-parse --short HEAD")
    puts "==git== #{stdout.read} #{stderr.read} #{wait_thr.value.exitstatus}"
    check.reference = stdout
    check.save

    stdin, stdout, stderr, wait_thr = Open3.popen3("rm -r #{path_temp}")
    puts "==rm -r== #{stdout.read} #{stderr.read} #{wait_thr.value.exitstatus}"
  end
end
