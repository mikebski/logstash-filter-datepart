# Logstash Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).

## License ##

Copyright (c) 2014–2015 Mike Baranski <http://www.mikeski.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## About

This plugin is useful if you want to easily query Logstash data on *day of week*, *hour of day*, or other parts of a date.  See the usage below for details on the output of the plugin.  The date parts that can be generated are:

* day
* wday
* yday
* month
* year
* hour
* min
* sec

## Documentation

### Installation

To manually install the plugin, download the gem and run:

`bin/plugin install --no-verify logstash-filter-dateparts-1.0.0.gem`

### Usage

To see the most basic usage, you can run the following (on Linux):

`echo "HI" | bin/logstash -e 'input { stdin {} } filter {dateparts { }} output { stdout { codec=> rubydebug}}'`

You could also use the logstash generator:

`bin/logstash -e 'input {  generator { lines => ["HI"] count => 1  } } filter {dateparts { }} output { stdout { codec=> rubydebug}}'`

Here is the sample output:

	{
		"message" => "HI",
		"@version" => "1",
		"@timestamp" => "2015-11-20T12:24:40.217Z",
		"host" => "mike-VirtualBox",
		"day" => 20,
		"wday" => 5,
		"yday" => 324,
		"month" => 11,
		"year" => 2015,
		"hour" => 12,
		"min" => 24,
		"sec" => 40
	}


This uses the default configuration, which generates the following fields from the `@timestamp` field of the event:

* day
* wday
* yday
* month
* year
* hour
* min
* sec

### Configuration

#### Fields

The generated fields are based on the date functions available in the [Ruby time class](http://ruby-doc.org/core-2.2.0/Time.html).  You can specify any valid function and it will be added to the event.

For example, this will add 2 fields, *sec* corresponding to `time.sec()` and *hour* corresponding to `time.hour()`:

    filter {
    	   dateparts {
	   	     "fields" => ["sec", "hour"]
	   }
    }

#### Time Field

By default, the plugin will use the *@timestamp* field, but you can specify a different one:

    filter {
    	   dateparts {
	   	     "time_field" => "some_other_field"
	   }
    }

#### Error Tags

By default, the tag *_dateparts_error* is added on exception.  You can specify different tag(s) like so:

    filter {
    	   dateparts {
	   	     "error_tags" => ["bad_dates", "xyz"]
	   }
    }
