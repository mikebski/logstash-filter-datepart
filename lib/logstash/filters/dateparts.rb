# encoding: utf-8
# Copyright (c) 2014–2016 Mike Baranski <http://www.mikeski.net>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# encoding: utf-8
require 'logstash/filters/base'
require 'logstash/namespace'

# This filter will add date parts to your record based on
# the timestamp field.
# 
class LogStash::Filters::DateParts < LogStash::Filters::Base
  # Setting the config_name here is required. This is how you
  # configure this filter from your Logstash config.
  #
  # filter {
  #   dateparts {
  #     
  #   }
  # }
  #
  config_name 'dateparts'
  config :fields, :validate => :array, :default => %w(day wday yday mday month year hour min sec), :required => true
  config :time_field, :validate => :string, :default => '@timestamp', :required => true
  config :error_tags, :validate => :array, :default => ['_dateparts_error'], :required => true
  config :duration, :validate => :hash, :required => false

  def register
    logger.debug? and logger.debug('DateParts filter registered')
  end

  def plugin_error(message, event)
    logger.error("DatePart filter error: #{message}")
    LogStash::Util::Decorators.add_tags(@error_tags, event, "filters/#{self.class.name}")
  end

  def get_time_from_field(f)
    if f.class == Time
      f
    elsif f.respond_to?('time')
      f.time
    elsif f.respond_to?('to_time')
      f.to_time
    else
      nil
    end
  end

  def get_hash_value(hash, key, default)
    if (hash[key] == nil)
      default
    else
      hash[key]
    end
  end

  def filter(event)
    event_time = get_time_from_field(event.get(@time_field))
    if event_time == nil
      plugin_error("Invalid time field #{@time_field}; Time field must be an instance of Time or provide a time method that returns one", event)
      return
    end
    logger.debug? and logger.debug("DateParts plugin filtering #{@time_field} time_field and adding fields: " + @fields.join(', '))
    @fields.each do |field|
      begin
        event.set(field, event_time.send(field))
      rescue
        plugin_error("No such method: #{field}\n", event)
      end
    end
    if @duration != nil
      start_time = get_time_from_field(event.get(get_hash_value(@duration, 'start_field', '@timestamp')))
      end_time = get_time_from_field(event.get(get_hash_value(@duration, 'end_field', '@timestamp')))

      begin
        result_field = get_hash_value(@duration, 'result_field', 'duration_result')
        duration = end_time - start_time
        event.set(result_field, duration)
      rescue
        plugin_error('Invalid start or end for duration.  Time fields must be an instance of Time or provide a time method that returns one', event)
        return
      end
    end

    filter_matched(event)
  end # def filter

end # class LogStash::Filters::DateParts
