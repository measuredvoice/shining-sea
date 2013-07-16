Shining Sea
===========

Use social-media data to highlight great communication.

## What it does

Shining Sea is a web application that summarizes metrics about recent government tweets (from a [social media registry](https://github.com/usagov/ringsail), for example) and highlights tweets that have performed well.

Tweets are scored using mission-driven metrics for reach, kudos, and engagement. A baseline metric for each tweet (the tweeting account's follower count) allows tweets to be compared apples-to-apples over time and across accounts.

A few exceptional tweets are featured each week on a top-N page, but any account in the list can be browsed to see the performance of recent tweets on the account.

## Quick Start



## How it works

Shining Sea is web application software written in Ruby, designed to be deployed to cloud infrastructure like Heroku or Amazon Web Services. 
 
After a standard 48-hour period, Shining Sea uses the Twitter API to retrieve a list of tweets from government Twitter accounts, including mission-driven metrics for those tweets. Once those metrics are collected, Shining Sea summarizes and normalizes them at a few levels and stores the summaries.

Once a week, Shining Sea generates reports about the previous week's tweets by account, by segment (agency, sector, or other tag), and by tweet. Exceptional tweets are uncovered by generating percentile ranks for each metric, as compared to previous tweets on the same account and (normalized) tweets across all accounts.

The reports can be stored indefinitely. They are generated as static files in HTML and JSON (data) format. The HTML files can be regenerated from the JSON data using a republisher.

## Installation

### On Heroku

### In an existing Rails environment

## Caveats

Shining Sea is designed to combine public data sources to produce another public data source. Data is not stored securely or hidden behind access controls. 

Shining Sea does not return metrics or summaries in real-time. Tweet metrics might not appear for a week or more after adding an account to a source registry.

The data store isn't a complete archive of all tweets. It trades 100% coverage for better performance and API friendliness. Use an archiving service or download from Twitter itself if a complete archive is needed.


## Contact

Shining Sea is a Measured Voice project. We're developing it to help government social-media writers.

Questions? Love this software? Email us at hi@measuredvoice.com.
