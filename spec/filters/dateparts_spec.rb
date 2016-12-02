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
require 'logstash/logging/logger'
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

  it 'Get time from field should work with Time' do
    f = LogStash::Filters::DateParts.new({})
    field_to_test = Time.new
    val = f.get_time_from_field(field_to_test);
    expect(val.class).to be(Time)
  end

  it 'Get time from field should work with DateTime' do
    f = LogStash::Filters::DateParts.new({})
    field_to_test = DateTime.new
    val = f.get_time_from_field(field_to_test);
    expect(val.class).to be(Time)
  end

  it 'Default config should result in filter with 8 functions, one error tag and @timestamp as the time field' do
    f = LogStash::Filters::DateParts.new({})

    expect(f.class).to eq(LogStash::Filters::DateParts)
    expect(f.fields.length).to eq(9)
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

    expect(event.to_hash.count).to eq(count + 9)
    expect(event.get('sec')).to be_truthy
    expect(event.get('hour')).to be_truthy
    expect(event.get('min')).to be_truthy
    expect(event.get('month')).to be_truthy
    expect(event.get('year')).to be_truthy
    expect(event.get('day')).to be_truthy
    expect(event.get('wday')).to be_truthy
    expect(event.get('mday')).to be_truthy
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
    expect(event.get('mday')).to be_nil
    expect(event.get('yday')).to be_nil
    expect(event.get('tags')).to be_nil
  end

  it 'Should set the error tag on an invalid time field' do
    event = get_event
    f = LogStash::Filters::DateParts.new({'time_field' => alt_ts_field})

    f.filter(event)
    expect(event.get('tags').include? '_dateparts_error').to eq(true)
  end

  it 'Should bail on an invalid date part' do
    event = get_event
    f = LogStash::Filters::DateParts.new({
                                             'fields' => %w(seczzz zzhour)
                                         })
    f.filter(event)
    expect(event.get('tags').include? '_dateparts_error').to eq(true)
  end

  it 'Should calculate a duration' do
    event = get_event
    f = LogStash::Filters::DateParts.new({
                                             'duration' => {
                                                 'start_field' => '@timestamp',
                                                 'end_field' => 'sometime',
                                                 'result_field' => 'duration'
                                             }
                                         })
    event.set('sometime', Time.new)
    f.filter(event)
    expect(event.get('tags')).to be_nil
    expect(event.get('duration')).to be > 0
  end

  it 'Should calculate a duration using 2 fields' do
    event = get_event
    f = LogStash::Filters::DateParts.new({
                                             'duration' => {
                                                 'start_field' => 'tstart',
                                                 'end_field' => 'tend',
                                                 'result_field' => 'duration'
                                             }
                                         })
    event.set('tstart', DateTime.new(2016, 1, 1, 12, 0, 0).to_time)
    event.set('tend', DateTime.new(2016, 1, 1, 12, 0, 0).to_time)
    f.filter(event)
    expect(event.get('tags')).to be_nil
    expect(event.get('duration')).to eq(0.0)
  end

  it 'Should calculate a duration of 1 second using 2 fields' do
    event = get_event
    f = LogStash::Filters::DateParts.new({
                                             'duration' => {
                                                 'start_field' => 'tstart',
                                                 'end_field' => 'tend',
                                                 'result_field' => 'duration'
                                             }
                                         })

    event.set('tstart', DateTime.new(2016, 1, 1, 23, 0, 0).to_time)
    event.set('tend', DateTime.new(2016, 1, 1, 23, 0, 1).to_time)
    f.filter(event)
    expect(event.get('tags')).to be_nil
    expect(event.get('duration')).to eq(1.0)
  end

  it 'Should calculate a duration of 3600 seconds using 2 fields and calculate datepart' do
    event = get_event
    f = LogStash::Filters::DateParts.new({
                                             #'fields' => %w(mday),
                                             'duration' => {
                                                 'start_field' => 'tstart',
                                                 'end_field' => 'tend',
                                                 'result_field' => 'duration'
                                             }
                                         })

    event.set('tstart', DateTime.new(2016, 1, 1, 20, 0, 0).to_time)
    event.set('tend', DateTime.new(2016, 1, 1, 21, 0, 0).to_time)
    f.filter(event)
    expect(event.get('tags')).to be_nil
    expect(event.get('duration')).to eq(3600.0)
    expect(event.get('mday')).to be > -1

  end

  it 'Should warn and return 0.0 if start and end are the same field' do
    event = get_event
    f = LogStash::Filters::DateParts.new({
                                             'duration' => {
                                                 'start_field' => 'tstart',
                                                 'end_field' => 'tstart',
                                                 'result_field' => 'duration'
                                             }
                                         })

    event.set('tstart', DateTime.new(2016, 1, 1, 20, 0, 0).to_time)
    f.filter(event)
    expect(event.get('tags')).to be_nil
    expect(event.get('duration')).to eq(0.0)
    expect(event.get('mday')).to be > -1
  end

  it 'Should return an error on nil start time' do
    event = get_event
    f = LogStash::Filters::DateParts.new({
                                             'duration' => {
                                                 'start_field' => 'tstart',
                                                 'end_field' => 'tend',
                                                 'result_field' => 'duration'
                                             }
                                         })

    event.set('tstart', nil)
    event.set('tend', DateTime.new(2016, 1, 1, 23, 0, 1).to_time)
    f.filter(event)
    expect(event.get('tags').include? '_dateparts_error').to eq(true)
  end

  it 'Should return an error on nil end time' do
    event = get_event
    f = LogStash::Filters::DateParts.new({
                                             'duration' => {
                                                 'start_field' => 'tstart',
                                                 'end_field' => 'tend',
                                                 'result_field' => 'duration'
                                             }
                                         })

    event.set('tstart', DateTime.new(2016, 1, 1, 23, 0, 1).to_time)
    event.set('tend', nil)
    f.filter(event)
    expect(event.get('tags').include? '_dateparts_error').to eq(true)
  end

  it 'Should use duration_result as the result field if it is not set' do
    event = get_event
    f = LogStash::Filters::DateParts.new({
                                             'duration' => {
                                                 'start_field' => 'tstart',
                                                 'end_field' => 'tend',
                                             }
                                         })

    event.set('tstart', DateTime.new(2016, 1, 1, 23, 0, 0).to_time)
    event.set('tend', DateTime.new(2016, 1, 1, 23, 0, 1).to_time)
    f.filter(event)
    expect(event.get('tags')).to be_nil
    expect(event.get('duration_result')).to eq(1.0)
  end

  it 'Should hit debugging statement' do
    event = get_event
    f = LogStash::Filters::DateParts.new({
                                             'duration' => {
                                                 'start_field' => 'tstart',
                                                 'end_field' => 'tend',
                                             }
                                         })
    #f.logger.setLevel(Level.valueOf('DEBUG'))
    event.set('tstart', DateTime.new(2016, 1, 1, 23, 0, 0).to_time)
    event.set('tend', DateTime.new(2016, 1, 1, 23, 0, 1).to_time)
    f.filter(event)
    expect(event.get('tags')).to be_nil
    expect(event.get('duration_result')).to eq(1.0)
  end

  it 'Should return value from hash' do
    f = LogStash::Filters::DateParts.new({
                                             'duration' => {
                                                 'start_field' => 'tstart',
                                                 'end_field' => 'tend',
                                             }
                                         })
    test_hash = {'val_name' => 1}
    val = f.get_hash_value(test_hash, 'val_name', 'blah');
    expect(val).to eq(1)
  end

  it 'Should return default value from hash' do
    f = LogStash::Filters::DateParts.new({
                                             'duration' => {
                                                 'start_field' => 'tstart',
                                                 'end_field' => 'tend',
                                             }
                                         })
    test_hash = {'val_name' => 1}
    val = f.get_hash_value(test_hash, 'xyza', 2);
    expect(val).to eq(2)
  end
end
