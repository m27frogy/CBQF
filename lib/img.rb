# encoding: utf-8

#--
########################################################################
# CollegeBoard QotD Fetcher
#
# CollegeBoard, SAT, and PSAT/NMSQT are registered trademarks of
# The College Board and National Merit Corporation and do not
# endorse this software.
#
#
# Copyright (c) 2015, m27frogy <m27frogy.roblox@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
########################################################################
#++

require "open-uri"
require "net/http"
require "openssl"
require "fileutils"
require "pathname"
require "tmpdir"

module CBQF
	module IMG
		# :category: IMG
		IMAGE_REGEX = /img.*?src="(.*?)"/i.freeze
		IMG_DIR = File.expand_path "#{Dir.tmpdir}/CBQF/".freeze
		FileUtils.mkdir_p IMG_DIR
		
		# Fetch IMG file and download it into a temp file
		def self.create_img_file(path)
			# Parse out the path properly
			file_name = File.basename path
			end_path = CBQF::IMG::IMG_DIR + "/" + file_name
			
			uri = URI.parse(CBQF::WEBSITE_URI)
			http = Net::HTTP.new(uri.host,uri.port)
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			resp = http.get(path)
			open(end_path,"wb") { |file|
				file.write(resp.body)
			}
			
			# Again, Lua habits. :P
			return end_path
		end

		# Parse out URIs and handle them nicely
		def self.parse_img_uri(html_doc)
			finished = html_doc.clone
			parsed = []
			html_doc.scan(CBQF::IMG::IMAGE_REGEX).each do |match|
				raise("Match should be a length of 1") if match.length != 1
				if not parsed.include? match[0] then
					file = create_img_file(match[0])
					parsed << file
					finished.gsub!(match[0],file)
				end
			end
			
			# This is Ruby style for ya. ;)
			html_doc = finished.encode("utf-8")
		end
	end
end
