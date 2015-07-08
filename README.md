# CBQF
A CollegeBoard QotD Fetcher, written in Ruby.

>CollegeBoard, SAT, and PSAT/NMSQT are registered trademarks of The College Board and National Merit Corporation and do not endorse this software.

#### Features
- Fetches QotD from within an automated instance of FireFox.
- Stores QotD in a special file for later use.
- Exports QotD in text format in two seperate files.
- Allows random shuffling and filtering of topics.

#### Bugs
- Cannot process QotD containing pictures and therefore skips all Mathematics problems.

## Pre-requisites
- Selenium-WebDriver
- Nokogiri
- Firefox (or similar browser if you know how to edit the code slightly)

## Preinstall

1.  Install Ruby with your [operating system specific instructions](https://www.ruby-lang.org/en/documentation/installation/).
2.  Download and install [Firefox](https://www.mozilla.org/en-US/firefox/new/).
3.  Install selenium-webdriver with a command similar to this: `gem install selenium-webdriver`
4.  Install Nokogiri with a command similar to this: `gem install nokogiri`

> I don't maintain these pre-install projects, so please look for online solutions if you have difficulty installing these.

## Install

1.  Clone this [repository](https://help.github.com/articles/cloning-a-repository/) or download and extract it as a zip.
2.  Double click the main.rb (if you enabled that in your ruby install) or navigate to the program's folder and execute `ruby main.rb`
