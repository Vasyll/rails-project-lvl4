# frozen_string_literal: true

require 'json'

class CheckRepositoryJob < ApplicationJob
  queue_as :default

  def perform(check_id)
    check = Repository::Check.find(check_id)
    check.start!
    repository = Repository.find(check.repository_id)

    path_temp = "./tmp/hexlet_quality_repositories/#{repository.full_name}"

    Open3.popen3("git clone #{repository.clone_url} #{path_temp}")

    if repository.language == 'javascript'
      stdout_eslint = Open3.popen3("./node_modules/eslint/bin/eslint.js #{path_temp} -f json -c ./.eslintrc.js --no-eslintrc") { |_stdin, stdout, _stderr, _wait_thr| [stdout.read] }
      check.result, check.issues_count = parse_eslint(JSON.parse(stdout_eslint.to_s))
    end

    if repository.language == 'ruby'
      stdout_rubocop = Open3.popen3("bundle exec rubocop #{path_temp} -f json >#{path_temp}/rubocop.json") { |_stdin, stdout, _stderr, _wait_thr| [stdout.read] }

      check.result, check.issues_count = parse_rubocop(JSON.parse(stdout_rubocop))
    end

    stdout_rev = Open3.popen3("git -C #{path_temp} rev-parse --short HEAD") { |_stdin, stdout, _stderr, _wait_thr| [stdout.read] }

    check.reference = stdout_rev.chop
    check.finish!
    check.save

    Open3.popen3("rm -r #{path_temp}")
  end

  private

  def parse_eslint(eslint_out)
    result = []
    issues_count = 0

    eslint_out.each do |file, _value|
      puts file
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
      issues_count += file['errorCount'].to_i
    end
    [JSON.generate(result).to_s, issues_count]
  end

  def parse_rubocop(rubocop_out)
    result = []
    files = rubocop_out['files']

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
    [JSON.generate(result).to_s, rubocop_out['summary']['offense_count'].to_i]
  end
end
