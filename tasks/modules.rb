
require 'tap/task'

class RubyforgeMspireGems < TapTask
  
  def process()
    gem_versions(/^ms-/)
  end

  def gem_versions(regexp) 
    `rubyforge login`
    `rubyforge config mspire`
    hash = YAML.load_file("#{ENV['HOME']}/.rubyforge/auto-config.yml")
    doublets = hash['release_ids'].select {|k,v| k =~ regexp }
    doublets.map do |k,v| 
      gem = v.keys.first 
      version = gem.split('-').last.sub(/\.gem$/,'')
      [k, version]
    end
  end

end
