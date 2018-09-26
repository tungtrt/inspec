# encoding: utf-8

require_relative './inspec_pb.rb'

module Inspec::Reporters
  class Proto < Base
    def render
      report.to_json
    end

    def report
      res = Inspec::Proto::Results.new(
        profiles: profiles,
      )
      output(res.to_proto, false)
    end

    private

    def profiles
      run_data[:profiles].map { |x| profile_result(x) }
    end

    def profile_result(profile)
      controls = profile[:controls] || []

      Inspec::Proto::ProfileResults.new(
        id: "ID??",
        name: profile[:name],
        version: profile[:version],
        sha256: profile[:sha256],
        controls: controls.map { |x| control_result(x) },
        skip_message: "",
      )
    end

    def control_result(control)
      results = control[:results] || []

      Inspec::Proto::ControlResults.new(
        id: control[:id],
        checksum: Digest::SHA256.hexdigest(control[:code]),
        results: results.map { |x| test_result(x) },
      )
    end

    def test_result(result)
      args = filter_nil({
        status: result[:status],
        code_desc: result[:code_desc],
        run_time: result[:run_time],
        start_time: result[:start_time],
        resource: result[:resource],
        message: result[:message],
        skip_message: result[:skip_message],
        exception: result[:exception],
        backtrace: result[:backtrace],
      })
      Inspec::Proto::TestResult.new(args)
    end

    def filter_nil(hash)
      Hash[hash.find_all { |_,v| !v.nil? }]
    end
  end
end
