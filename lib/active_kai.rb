require 'memcache'

class ActiveKai
  cattr_accessor :servers
  cattr_writer :namespace
  attr_accessor :original_key

  def self.kai_servers(servers)
    self.servers = servers
  end

  def self.kai_key_index(idx)
    @_kai_key_index_ = idx
  end

  def self.kai_key_prefix(str)
    @_kai_key_prefix_ = str
  end

  def initialize(params)
    @params = []
    params.each do |k,v|
      @params << k
      instance_variable_set("@#{k}",v)
    end
  end

  def self.create(params)
    self.new(params).save
  end
    
  def method_missing(name,arg=nil)
    @params.each do |pr|
      if name == "#{pr}=".to_sym
        return instance_variable_set("@#{pr}",arg)
      elsif name == "#{pr}".to_sym
        return instance_variable_get("@#{pr}")
      end
    end
    super
  end

  def save
    res = self.class.kai.set self.key,self,0
    if self.changed?
      self.class.find(self.original_key).destroy
    end
    res.match(/STORED/) ? true : false
  end

  def changed?
    if self.original_key.nil?
      false
    else
      self.key != self.original_key      
    end
  end

  def destroy
    self.class.kai.delete self.key
  end

  def self.find(id)
    oj = self.kai.get self.key(id)
    return if oj.nil?
    oj.original_key = oj.key
    oj
  end

  def self.kai
    if defined?(@@kai) && !@@kai.nil?
      return @@kai 
    end
    if !@@servers.nil?
      @@kai = MemCache.new
      @@kai.servers = @@servers
      @@kai
    end
  end

  def namespace
    self.class.namespace 
  end

  def self.namespace
    defined?(@@namespace) ? @@namespace : File.basename(RAILS_ROOT)
  end

  def prefix
    self.class.prefix
  end
  
  def self.prefix
    if !@_kai_key_prefix_.nil?
      @_kai_key_prefix_
    else
      [self,RAILS_ENV].join(".")
    end
  end

  def key
    v = self.instance_variable_get("@#{self.class.key_index}")
    if v.nil?
      raise
    end
    [namespace,prefix].join(".") + "/" +  v.to_s
  end

  def self.key(id)
    [namespace,prefix].join(".") + "/" + id.to_s
  end

  def self.key_index
    @_kai_key_index_ || :id
  end
end

