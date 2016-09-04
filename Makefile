# Copyright (c) 2014–2015 Mike Baranski <http://www.mikeski.net>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Simple Makefile using gem2.0 to build Logstash plugin
GEM=gem2.0
LOGSTASH_HOME=/home/mike/apps/logstash-2.0.0
VERSION=2.0
GEM_NAME=logstash-filter-dateparts-$(VERSION).gem
MARKDOWN_CMD=markdown

readme: README.md
	$(MARKDOWN_CMD) README.md >README.html

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
