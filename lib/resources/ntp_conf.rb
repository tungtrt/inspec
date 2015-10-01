# encoding: utf-8
# copyright: 2015, Vulcano Security GmbH
# license: All rights reserved

require 'utils/simpleconfig'

# Usage:
#
# describe ntp_conf do
#   its('server') { should_not eq nil }
#   its('restrict') { should include '-4 default kod notrap nomodify nopeer noquery'}
# end

class NtpConf < Vulcano.resource(1)
  name 'ntp_conf'

  def initialize(path = nil)
    @conf_path = path || '/etc/ntp.conf'
  end

  def to_s
    'ntp_conf'
  end

  def method_missing(name)
    param = read_params[name.to_s]
    # extract first value if we have only one value in array
    return param[0] if param.is_a?(Array) and param.length == 1
    param
  end

  private

  def read_params
    return @params if defined?(@params)

    if !vulcano.file(@conf_path).file?
      skip_resource "Can't find file \"#{@conf_path}\""
      return @params = {}
    end

    content = vulcano.file(@conf_path).content
    if content.empty? && vulcano.file(@conf_path).size > 0
      skip_resource "Can't read file \"#{@conf_path}\""
      return @params = {}
    end

    # parse the file
    conf = SimpleConfig.new(
      content,
      assignment_re: /^\s*(\S+)\s+(.*)\s*$/,
      multiple_values: true,
    )
    @params = conf.params
  end
end
