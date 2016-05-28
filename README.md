>The CollegeBoard no longer provides the Question of the Day through a web browser, making this program effectively useless.  There will be no more updates.  Sorry.

## CBQF

A CollegeBoard QotD Fetcher, written in Ruby.

>CollegeBoard, SAT, and PSAT/NMSQT are registered trademarks of The College Board and National Merit Corporation and do not endorse this software.

```
Copyright (c) 2015, m27frogy <m27frogy.roblox@gmail.com>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

#### Features
- Fetches QotD from within an automated instance of FireFox.
- Stores QotD in a special file for later use.
- Exports QotD in PDF format for printing conveniently.
- Allows random shuffling and filtering of topics.

#### Bugs
- TBD.

## Pre-requisites
- Selenium-WebDriver
- Nokogiri
- PDFKit
- Firefox (or similar browser if you know how to edit the code slightly)

## Preinstall

1.  Install Ruby with your [operating system specific instructions](https://www.ruby-lang.org/en/documentation/installation/).
2.  Download and install [Firefox](https://www.mozilla.org/en-US/firefox/new/).
3.  Install selenium-webdriver with a command similar to this: `gem install selenium-webdriver`
4.  Install Nokogiri with a command similar to this: `gem install nokogiri`
5.  Install PDFKit with a command similar to this: `gem install pdfkit`

> I don't maintain these pre-install projects, so please look for online solutions if you have difficulty installing these.

## Install

1.  Clone this [repository](https://help.github.com/articles/cloning-a-repository/) or download and extract it as a zip.
2.  Double click the main.rb (if you enabled that in your ruby install) or navigate to the program's folder and execute `ruby main.rb`
