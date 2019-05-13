@echo on

setx path "%path%;c:\tools\ruby26\bin;c:\tools\msys64\usr\bin"
cd \vagrant

ruby -v
gem -v
gem install bundler
bundle install
bundle exec rake test:functional:windows
