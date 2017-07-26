#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# Copyright © 2012 Diego Elio Pettenò <flameeyes@flameeyes.eu>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and

require 'set'

seen_ids = Set.new
res = 0

# read reserved id range from the id-range file so that it can be
# configured on a per-repository basis.
range = Range.new(*File.read('id-range').rstrip.split('-').map(&:to_i))

# open all the rule files
Dir["**/*.conf"].each do |rulefile|
  # read the content
  content = File.read(rulefile)

  lineno = 0
  this_chained = next_chained = false
  prevline = nil

  # for each line in the rule file
  content.each_line do |line|
    lineno += 1

    # handle continuation lines
    line = (prevline + line) unless prevline.nil?

    # remove comments
    line.gsub!(/^([^'"]|'[^']+'|"[^"]+")#.*/) { $1 }

    if line =~ /\\\n$/
      prevline = line.gsub(/\\\n/, '')
      next
    else
      prevline = nil
    end

    # skip if it's an empty line (this also skip comment-only lines)
    next if line =~ /(?:^\s+$|^#)/

    this_chained = next_chained
    next_chained = false

    # split the directive in its components, considering quoted strings
    directive = line.scan(/([^'"\s][^\s]*[^'"\s]|'(?:[^']|\\')*[^\\]'|"(?:[^"]|\\")*[^\\]")(?:\s+|$)/).flatten
    directive.map! do |piece|
      # then make sure to split the quoting out of the quoted strings
      (piece[0] == '"' || piece[0] == "'") ? piece[1..-2] : piece
    end

    # skip if it's not a SecRule or SecAction
    case directive[0]
    when "SecRule"
      rawrule = directive[3]
    when "SecAction"
      rawrule = directive[1]
    else
      next
    end

    # get the rule and split in its components
    rule = (rawrule || "").gsub(/(?:^"|"$)/, '').split(/\s*,\s*/)

    if rule.include?("chain")
      next_chained = true
    end

    ids = rule.find_all { |piece| piece =~ /^id:/ }
    if ids.size > 1
      $stderr.puts "#{rulefile}:#{lineno} rule with multiple ids"
      next
    elsif ids.size == 0
      id = nil
    else
      id = ids[0].sub(/^id:/, '').gsub(/(?:^'|'$)/, '').to_i
    end

    if this_chained
      unless id.nil?
        $stderr.puts "#{rulefile}:#{lineno} chained rule with id"
        res = 1
      end
      next
    elsif id.nil?
      $stderr.puts "#{rulefile}:#{lineno} rule missing id (#{rule.join(',')})"
      res = 1
      next
    elsif ! range.include?(id)
      $stderr.puts "#{rulefile}:#{lineno} rule with id #{id} outside of reserved range #{range}"
      res = 1
    elsif seen_ids.include?(id)
      $stderr.puts "#{rulefile}:#{lineno} rule with duplicated id #{id}"
      res = 1
    end

    seen_ids << id
  end
end

exit res
