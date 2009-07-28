require 'memcache'

class ActiveKai
  @@kai = nil
  attr_accessor :original_key
  def self.kai_servers(servers)
    self.servers = servers
  end

  def self.servers=(servers)
    @@servers = servers
  end

  def self.kai_key_index(idx)
    @_kai_key_index_ = idx
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
  end

  def save
    res = self.class.kai.set self.key,self,0
    res.match(/STORED/) ? true : false
    if self.changed?
      self.class.find(self.original_key).destroy
    end
  end

  def changed?
    self.key == self.original_key
  end

  def destroy
    self.class.kai.delete self.key
  end

  def self.find(id)
    oj = self.kai.get self.key(id)
    oj.original_key = oj.key
  end

  def self.kai
    if !@@kai.nil?
      return @@kai 
    end
    if !@@servers.nil?
      @@kai = MemCache.new
      @@kai.servers = @@servers
      @@kai
    end
  end

  def prefix
    self.class.prefix
  end
  
  def self.prefix
    [self,RAILS_ENV].join("_")
  end

  def key
    v = self.instance_variable_get("@#{self.class.key_index}")
    if v.nil?
      raise
    end
    prefix + "/" +  v.to_s
  end

  def self.key(id)
    prefix + "/" + id.to_s
  end

  def self.key_index
    @_kai_key_index_ || :id
  end
end

