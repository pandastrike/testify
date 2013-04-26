require "starter/tasks/npm"
require "starter/tasks/git"
require "starter/tasks/markdown"

task "build" => "bundle:example"

task "bundle:example" do
  Dir.chdir "examples/browser" do
    sh "ark package < manifest.json > bundle.js"
  end
end
