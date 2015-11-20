# Simple Makefile using gem2.0 to build Logstash plugin
GEM=gem2.0
LOGSTASH_HOME=/home/mike/apps/logstash-2.0.0
VERSION=1.0.0
GEM_NAME=logstash-filter-dateparts-$(VERSION).gem

readme: README.md
	markdown README.md >README.html

gem : spec/filters/dateparts_spec.rb logstash-filter-dateparts.gemspec lib/logstash/filters/dateparts.rb readme
	$(GEM) build logstash-filter-dateparts.gemspec

clean:
	rm -f $(GEM_NAME)
	find ./ -name '*~' -exec rm {} \;

rspec: clean gem
	bundle exec rspec

install: rspec
	$(LOGSTASH_HOME)/bin/plugin install --no-verify $(GEM_NAME)

integration_test: install
	echo "HI" | $(LOGSTASH_HOME)/bin/logstash -e 'input { stdin {} } filter {dateparts { }} output { stdout { codec=> rubydebug}}'
