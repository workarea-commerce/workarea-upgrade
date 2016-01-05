namespace :weblinc do
  namespace :upgrade do
    desc 'Migrate the database'
    task :migrate, [:from, :to] do
      # Task goes here
    end

    desc 'Read the release notes for the current version'
    task :release_notes do
      # Task goes here
    end

    desc 'Read a diff for files customized in this application'
    task :diff do
      # Task goes here
    end
  end
end
