# frozen_string_literal: true

require 'json'

class CheckRepositoryJob < ApplicationJob
  queue_as :default

  def perform(check_id)
    check = Repository::Check.find(check_id)
    check.start!
    repository = Repository.find(check.repository_id)

    path_temp = "./tmp/hexlet_quality_repositories/#{repository.full_name}"
    _stdin, stdout, stderr, wait_thr = Open3.popen3("git clone #{repository.clone_url} #{path_temp}")
    Rails.logger.debug { "==git clone== #{stdout.read} #{stderr.read} #{wait_thr.value.exitstatus}" }

    if repository.language == 'javascript'
      _stdin, stdout, stderr, wait_thr = Open3.popen3("./node_modules/eslint/bin/eslint.js #{path_temp} -f json -c ./.eslintrc.js --no-eslintrc >#{path_temp}/eslint.json")
      Rails.logger.debug { "==eslint== #{stdout.read} #{stderr.read} #{wait_thr.value.exitstatus}" }

      eslint_out = JSON.parse(File.readlines("#{path_temp}/eslint.json")[2])
      check.result, check.issues_count = parse_eslint(eslint_out)
    end

    if repository.language == 'ruby'
      _stdin, stdout, stderr, wait_thr = Open3.popen3("bundle exec rubocop #{path_temp} -f json -c ./.rubocop_for_repo.yml >#{path_temp}/rubocop.json")
      Rails.logger.debug { "==rubocop== #{stdout.read} #{stderr.read} #{wait_thr.value.exitstatus}" }

      rubocop_out = JSON.parse(File.read("#{path_temp}/rubocop.json"))
      check.result, check.issues_count = parse_rubocop(rubocop_out)
    end

    _stdin, stdout, stderr, wait_thr = Open3.popen3("git -C #{path_temp} rev-parse --short HEAD")
    Rails.logger.debug { "==git== #{stderr.read} #{wait_thr.value.exitstatus}" }
    check.reference = stdout.read.chop
    check.finish!
    check.save

    _stdin, stdout, stderr, wait_thr = Open3.popen3("rm -r #{path_temp}")
    Rails.logger.debug { "==rm -r== #{stdout.read} #{stderr.read} #{wait_thr.value.exitstatus}" }
  end

  private

  def parse_eslint(eslint_out)
    result = []
    issues_count = 0

    eslint_out.each do |file, _value|
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
