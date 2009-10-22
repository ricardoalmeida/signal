class Project < ActiveRecord::Base
  BASE_PATH = "#{RAILS_ROOT}/public/projects"

  has_friendly_id :name

  validates_presence_of :name, :url, :email
  has_many :builds

  def after_create
    execute "cd #{BASE_PATH} && git clone #{url} #{name}"
  end

  def status
    builds.last.try(:status) || ''
  end

  def build
    builds.create
  end

  def deploy
    run "rake inploy:remote:update >"
  end

  def last_builded_at
    builds.last.try(:created_at)
  end

  protected

  def update
    run "git pull origin master >"
  end

  def last_commit
    Git.open(path).log.first
  end

  def rake_build
    result = run "rake build -N RAILS_ENV=test >>"
    return result, File.open(log_path).read
  end

  private

  def path
    "#{BASE_PATH}/#{name}"
  end

  def log_path
    "#{RAILS_ROOT}/tmp/#{name}"
  end

  def run(cmd)
    execute "cd #{path} && #{cmd} #{log_path} 2>&1"
  end

  def execute(command)
    Kernel.system command
  end
end
