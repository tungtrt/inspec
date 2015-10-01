# encoding: utf-8
# copyright: 2015, Vulcano Security GmbH
# license: All rights reserved

require 'utils/simpleconfig'

class SshConf < Vulcano.resource(1)
  name 'ssh_config'

  def initialize(conf_path = nil, type = nil)
    @conf_path = conf_path || '/etc/ssh/ssh_config'
    typename = (@conf_path.include?('sshd') ? 'Server' : 'Client')
    @type = type || "SSH #{typename} configuration #{conf_path}"
  end

  def to_s
    @type
  end

  def content
    read_content
  end

  def params(*opts)
    opts.inject(read_params) do |res, nxt|
      res.respond_to?(:key) ? res[nxt] : nil
    end
  end

  def method_missing(name)
    param = read_params[name.to_s]
    return nil if param.nil?
    # extract first value if we have only one value in array
    return param[0] if param.length == 1
    param
  end

  private

  def read_content
    return @content if defined?(@content)
    file = vulcano.file(@conf_path)
    if !file.file?
      return skip_resource "Can't find file \"#{@conf_path}\""
    end

    @content = file.content
    if @content.empty? && file.size > 0
      return skip_resource "Can't read file \"#{@conf_path}\""
    end

    @content
  end

  def read_params
    return @params if defined?(@params)
    return @params = {} if read_content.nil?
    conf = SimpleConfig.new(
      read_content,
      assignment_re: /^\s*(\S+?)\s+(.*?)\s*$/,
      multiple_values: true,
    )
    @params = conf.params
  end
end

class SshdConf < SshConf
  name 'sshd_config'

  def initialize(path = nil)
    super(path || '/etc/ssh/sshd_config')
  end
end
