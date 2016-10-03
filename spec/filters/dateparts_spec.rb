# coding: utf-8
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

require 'spec_helper'
require 'logstash/filters/dateparts'
require 'logstash/timestamp'
require 'logstash/event'

def get_event(contents = {})
  contents['@timestamp'] = LogStash::Timestamp.new
  LogStash::Event.new(contents)
end

describe LogStash::Filters::DateParts do
  default_ts = '@timestamp'
  alt_ts_field = 'zxlk'
  
  it 'Default config should result in filter with 8 functions, one error tag and @timestamp as the time field' do
    f = LogStash::Filters::DateParts.new({})
    
    expect(f.class).to eq(LogStash::Filters::DateParts)
    expect(f.fields.length).to eq(8)
    expect(f.time_field).to eq(default_ts)
    expect(f.error_tags.length).to eq(1)
  end

  it 'Config should result in filter with 2 functions and the alt timestamp field' do
    f = LogStash::Filters::DateParts.new({
                                           'fields' => %w(sec hour),
                                           'time_field' => alt_ts_field
                                         })
    
    expect(f.class).to eq(LogStash::Filters::DateParts)
    expect(f.fields.length).to eq(2)
    expect(f.fields[0]).to eq('sec')
    expect(f.time_field).to eq(alt_ts_field)
  end

  it 'Should generate the default fields (8 of them)' do
    event = get_event
    count = event.to_hash.count
    f = LogStash::Filters::DateParts.new({})
    f.filter(event)
    
    expect(event.to_hash.count).to eq(count + 8)
    expect(event.get('sec')).to be_truthy
    expect(event.get('hour')).to be_truthy
    expect(event.get('min')).to be_truthy
    expect(event.get('month')).to be_truthy
    expect(event.get('year')).to be_truthy
    expect(event.get('day')).to be_truthy
    expect(event.get('wday')).to be_truthy
    expect(event.get('yday')).to be_truthy
    expect(event.get('tags')).to be_nil
  end

  it 'Should generate only the specified fields' do
    event = get_event
    count = event.to_hash.count
    f = LogStash::Filters::DateParts.new({
                                           'fields' => %w(sec hour)
                                         })
    f.filter(event)
    expect(event.to_hash.count).to eq(count + 2)
    expect(event.get('sec')).to be_truthy
    expect(event.get('hour')).to be_truthy
    expect(event.get('min')).to be_nil
    expect(event.get('month')).to be_nil
    expect(event.get('year')).to be_nil
    expect(event.get('day')).to be_nil
    expect(event.get('wday')).to be_nil
    expect(event.get('yday')).to be_nil
    expect(event.get('tags')).to be_nil
  end

  it 'Should set the error tag on an invalid time field' do
    event = get_event
    f = LogStash::Filters::DateParts.new({ 'time_field' => alt_ts_field })
    
    f.filter(event)
    expect(event.get('tags').include? '_dateparts_error').to eq(true)
  end
end
